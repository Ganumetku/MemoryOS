import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Profile section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withAlpha(30),
                  child: Text(
                    'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Account', style: theme.textTheme.titleLarge),
                    const Text(
                      'user@memoryos.ai',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Preferences',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme',
              trailing: Switch(
                value: theme.brightness == Brightness.dark,
                onChanged: (val) {},
              ),
            ),
            _SettingsTile(
              icon: Icons.sync,
              title: 'Supabase Cloud Sync',
              trailing: Switch(value: true, onChanged: (val) {}),
            ),
            _SettingsTile(
              icon: Icons.security_outlined,
              title: 'Local Vault Encryption',
              trailing: Switch(value: true, onChanged: (val) {}),
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const _VersionTile(),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withAlpha(26),
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => context.go('/onboarding'),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _taps++;
        });
        if (_taps >= 7) {
          _taps = 0;
          context.push('/developer-dashboard');
        }
      },
      child: const _SettingsTile(
        icon: Icons.info_outline,
        title: 'Version',
        trailing: Text(
          '1.0.0 (Build 1)',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: theme.colorScheme.surface,
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
