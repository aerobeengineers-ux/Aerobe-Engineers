import 'package:flutter/material.dart';

import '../api.dart';
import '../shared/chat_screen.dart';
import '../shared/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dashboard = Api.get('/employee/dashboard').then((d) => d as Map<String, dynamic>);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboard,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingView();
            if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
            final d = snap.data!;
            final rating = d['rating'] as Map<String, dynamic>;
            final checklist = (d['profile_checklist'] as List).cast<Map<String, dynamic>>();
            final clients = (d['clients'] as List).cast<Map<String, dynamic>>();
            final done = checklist.where((c) => c['done'] == true).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your rating', style: Theme.of(context).textTheme.titleMedium),
                      Text(rating['count'] == 0
                          ? 'No ratings yet. Clients can rate you after working together.'
                          : '★ ${rating['average']} from ${rating['count']} client rating${rating['count'] == 1 ? '' : 's'}'),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Profile: $done of ${checklist.length} done',
                          style: Theme.of(context).textTheme.titleMedium),
                      for (final c in checklist)
                        Text('${c['done'] == true ? '✓' : '○'} ${c['label']}'),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Your clients', style: Theme.of(context).textTheme.titleMedium),
                if (clients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No clients yet. When you are assigned to a job, the client appears here.'),
                  ),
                for (final c in clients)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c['client'] as String),
                    subtitle: Text(c['job_title'] as String? ?? 'General conversation'),
                    trailing: (c['unread'] as int) > 0
                        ? CircleAvatar(radius: 11, child: Text('${c['unread']}', style: const TextStyle(fontSize: 11)))
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            assignmentId: c['assignment_id'] as int, title: c['client'] as String),
                      ));
                      _refresh();
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
