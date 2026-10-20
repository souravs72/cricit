import 'package:flutter/material.dart';

/// T22 (login) + T31 (profile, saved cards, settings, account delete).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profile', style: t.headlineMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {}, child: const Text('Sign in with your phone number')),
          const SizedBox(height: 24),
          const ListTile(title: Text('Language'), trailing: Text('English')),
          const ListTile(title: Text('Notifications')),
          const ListTile(title: Text('Night mode')),
          const ListTile(title: Text('Text size')),
        ],
      ),
    );
  }
}
