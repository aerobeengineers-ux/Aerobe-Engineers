import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../session.dart';
import '../shared/widgets.dart';
import 'avatar.dart';

/// The employee's own profile: photo, headline, summary, portfolio and the four lists.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

const Map<String, String> _kindLabels = {
  'experience': 'Experience',
  'education': 'Education',
  'certificate': 'Certificates',
  'project': 'Projects',
};

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  final _headline = TextEditingController();
  final _summary = TextEditingController();
  final _portfolio = TextEditingController();
  bool _busy = false;
  bool _loadedForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _summary.dispose();
    _portfolio.dispose();
    super.dispose();
  }

  void _load() {
    _profile = Api.get('/employee/profile').then((d) => d as Map<String, dynamic>);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _profile;
  }

  void _fillForm(Map<String, dynamic> p) {
    if (_loadedForm) return;
    _loadedForm = true;
    _headline.text = (p['headline'] as String?) ?? '';
    _summary.text = (p['summary'] as String?) ?? '';
    _portfolio.text = (p['portfolio_url'] as String?) ?? '';
  }

  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveBasics() => _run(() async {
        await Api.put('/employee/profile', {
          'headline': _headline.text.trim(),
          'summary': _summary.text.trim(),
          'portfolio_url': _portfolio.text.trim(),
        });
        _toast('Profile saved.');
        _loadedForm = false;
        await _refresh();
      });

  Future<void> _changePhoto() => _run(() async {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
        if (picked == null) return;
        final prepared = prepareAvatar(await picked.readAsBytes());
        if (prepared == null) {
          _toast('This picture could not be made small enough. Try a simpler photo.');
          return;
        }
        await Api.upload('/employee/photo', 'photo', prepared, 'profile.jpg');
        _toast('Photo updated.');
        await _refresh();
      });

  Future<void> _removePhoto() => _run(() async {
        await Api.delete('/employee/photo');
        await _refresh();
      });

  Future<void> _addItem(String kind) async {
    final title = TextEditingController();
    final org = TextEditingController();
    final period = TextEditingController();
    final description = TextEditingController();
    final link = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${_kindLabels[kind]!.toLowerCase()}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: org, decoration: const InputDecoration(labelText: 'Company / institution')),
            TextField(controller: period, decoration: const InputDecoration(labelText: 'Period, e.g. 2021 - 2024')),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Details')),
            TextField(controller: link, decoration: const InputDecoration(labelText: 'Link (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (saved == true) {
      await _run(() async {
        await Api.post('/employee/items', {
          'kind': kind,
          'title': title.text.trim(),
          'org': org.text.trim(),
          'period': period.text.trim(),
          'description': description.text.trim(),
          'link': link.text.trim(),
        });
        await _refresh();
      });
    }
    for (final c in [title, org, period, description, link]) {
      c.dispose();
    }
  }

  Future<void> _deleteItem(int id) => _run(() async {
        await Api.delete('/employee/items/$id');
        await _refresh();
      });

  @override
  Widget build(BuildContext context) {
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
            _fillForm(p);
            final items = p['items'] as Map<String, dynamic>;
            return AbsorbPointer(
              absorbing: _busy,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('Profile photo', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text('Square, 10 KB or smaller. The app shrinks your photo for you.',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        CircleAvatar(
                          radius: 44,
                          backgroundImage: p['has_photo'] == true
                              ? NetworkImage(Api.photoUrl(_ownId), headers: Api.authHeaders)
                              : null,
                          onBackgroundImageError: (_, __) {},
                          child: p['has_photo'] == true ? null : const Icon(Icons.person, size: 40),
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          OutlinedButton(onPressed: _changePhoto, child: const Text('Change photo')),
                          if (p['has_photo'] == true) ...[
                            const SizedBox(width: 8),
                            TextButton(onPressed: _removePhoto, child: const Text('Remove')),
                          ],
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    color: Color(0xFFFFF4DE),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Please don\'t share personal details such as your email address or mobile number. '
                        'Use the chat on this app to talk with clients.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _headline, maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Headline', hintText: 'e.g. BIM specialist, Revit')),
                  const SizedBox(height: 8),
                  TextField(controller: _summary, maxLines: 5, maxLength: 1500,
                      decoration: const InputDecoration(labelText: 'Summary', alignLabelWithHint: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _portfolio, keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'Portfolio link (optional)', hintText: 'https://')),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _saveBasics, child: const Text('Save')),
                  for (final entry in _kindLabels.entries) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: Text(entry.value, style: Theme.of(context).textTheme.titleMedium)),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        onPressed: () => _addItem(entry.key),
                      ),
                    ]),
                    if ((items[entry.key] as List).isEmpty)
                      const Text('Nothing added yet.', style: TextStyle(fontSize: 12)),
                    for (final it in items[entry.key] as List)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${(it as Map)['title']}'),
                        subtitle: Text([it['org'], it['period']].where((x) => x != null && '$x'.isNotEmpty).join(' · ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteItem(it['id'] as int),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The logged-in employee's id (used for the photo address).
  int get _ownId => (session.user?['id'] as int?) ?? 0;
}
