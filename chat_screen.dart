import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';

/// One conversation. New messages are fetched every 6 seconds.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.assignmentId, required this.title});
  final int assignmentId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  int _lastId = 0;
  bool _active = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final data = await Api.get('/chats/${widget.assignmentId}/messages?after=$_lastId')
          as Map<String, dynamic>;
      if (!mounted) return;
      final fresh = (data['messages'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _active = data['active'] as bool;
        _messages.addAll(fresh);
        if (fresh.isNotEmpty) _lastId = fresh.last['id'] as int;
      });
      if (fresh.isNotEmpty) _scrollToEnd();
    } on ApiException {
      // Keep the thread on screen; the next poll tries again.
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Api.post('/chats/${widget.assignmentId}/messages', {'body': text});
      _input.clear();
      await _poll();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _Bubble(message: _messages[i]),
                  ),
          ),
          if (_active)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Write a message…', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ]),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This conversation has ended.', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final mine = message['mine'] as bool;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? accent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine)
              Text(message['sender'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Text(message['body'] as String,
                style: TextStyle(color: mine ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Text(message['at'] as String,
                style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.black45)),
          ],
        ),
      ),
    );
  }
}
