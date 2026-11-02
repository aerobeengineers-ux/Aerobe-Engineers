import 'package:flutter/material.dart';

import '../api.dart';
import 'chat_screen.dart';
import 'widgets.dart';

/// Every conversation the user has, for clients and employees alike.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  late Future<List<dynamic>> _chats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _chats = Api.get('/chats').then((d) => (d as Map<String, dynamic>)['chats'] as List<dynamic>);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _chats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _chats,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingView();
            if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
            final chats = snap.data!;
            if (chats.isEmpty) {
              return const EmptyView(text: 'No conversations yet. They start when a specialist is assigned to a job.');
            }
            return ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = chats[i] as Map<String, dynamic>;
                final unread = c['unread'] as int;
                return ListTile(
                  leading: CircleAvatar(child: Text((c['with'] as String).substring(0, 1))),
                  title: Text(c['with'] as String),
                  subtitle: Text(c['job_title'] as String? ?? 'General conversation'),
                  trailing: unread > 0
                      ? CircleAvatar(radius: 11, child: Text('$unread', style: const TextStyle(fontSize: 11)))
                      : (c['active'] == false ? const Text('Ended') : null),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(assignmentId: c['assignment_id'] as int, title: c['with'] as String),
                    ));
                    _refresh();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
