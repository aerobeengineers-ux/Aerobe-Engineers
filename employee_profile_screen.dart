import 'package:flutter/material.dart';

import '../api.dart';
import '../config.dart';
import '../session.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'widgets.dart';

/// An employee's profile as a client sees it, with rating. Employees see their own profile here too.
class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key, required this.employeeId, this.chatAssignmentId});
  final int employeeId;
  final int? chatAssignmentId;

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  int _stars = 0;
  final TextEditingController _comment = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _load() {
    _profile = Api.get('/employees/${widget.employeeId}')
        .then((d) => (d as Map<String, dynamic>)['profile'] as Map<String, dynamic>);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _profile;
  }

  Future<void> _rate(Map<String, dynamic> profile) async {
    if (_stars < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a rating first.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.post('/employees/${widget.employeeId}/rate', {'stars': _stars, 'comment': _comment.text.trim()});
      _comment.clear();
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = session.role == 'customer';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profile,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingView();
            if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
            final p = snap.data!;
            final rating = p['rating'] as Map<String, dynamic>;
            final items = p['items'] as Map<String, dynamic>;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: p['has_photo'] == true
                        ? NetworkImage(Api.photoUrl(widget.employeeId), headers: Api.authHeaders)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: p['has_photo'] == true ? null : Text((p['name'] as String).substring(0, 1)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['name'] as String, style: Theme.of(context).textTheme.titleLarge),
                      if ((p['headline'] as String?)?.isNotEmpty ?? false)
                        Text(p['headline'] as String, style: const TextStyle(color: accent)),
                      const SizedBox(height: 4),
                      Text(rating['count'] == 0
                          ? 'Not rated yet'
                          : '★ ${rating['average']} (${rating['count']} rating${rating['count'] == 1 ? '' : 's'})'),
                    ]),
                  ),
                ]),
                if (widget.chatAssignmentId != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(assignmentId: widget.chatAssignmentId!, title: p['name'] as String),
                    )),
                  ),
                ],
                if ((p['summary'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  Text(p['summary'] as String),
                ],
                for (final entry in _sections.entries)
                  if ((items[entry.key] as List).isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(entry.value, style: Theme.of(context).textTheme.titleMedium),
                    for (final it in items[entry.key] as List)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${(it as Map)['title']}${it['org'] != null ? ' — ${it['org']}' : ''}'),
                        subtitle: Text([it['period'], it['description']].where((x) => x != null).join('\n')),
                      ),
                  ],
                const SizedBox(height: 24),
                Text('Ratings', style: Theme.of(context).textTheme.titleMedium),
                if (isClient) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var n = 1; n <= 5; n++)
                        IconButton(
                          icon: Icon(n <= _stars ? Icons.star : Icons.star_border, color: Colors.amber),
                          onPressed: () => setState(() => _stars = n),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _comment,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Comment (optional)'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _rate(p),
                    child: Text(p['my_rating'] == null ? 'Submit rating' : 'Update rating'),
                  ),
                ],
                const SizedBox(height: 12),
                for (final r in p['ratings'] as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('★ ${(r as Map)['stars']} · ${r['client']} · ${r['date']}'),
                    subtitle: r['comment'] != null ? Text(r['comment'] as String) : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const Map<String, String> _sections = {
  'experience': 'Experience',
  'education': 'Education',
  'certificate': 'Certificates',
  'project': 'Projects',
};
