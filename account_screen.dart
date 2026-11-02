import 'package:flutter/material.dart';

import '../api.dart';
import '../session.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = session.user ?? {};
    final role = user['role'] == 'employee' ? 'Employee' : 'Client';
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user['name'] as String? ?? ''),
            subtitle: Text('${user['email'] ?? ''}\n$role account'),
            isThreeLine: true,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy'),
            subtitle: Text('Your chats stay on Aerobe Engineers. Please don\'t share personal contact details with specialists or clients.'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () => Api.logout(),
          ),
        ],
      ),
    );
  }
}
