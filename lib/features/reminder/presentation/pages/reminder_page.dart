import 'package:flutter/material.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders & Prompts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Memory Prompts', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'MemoryOS schedules intelligent reminders to ask you about key moments in your life.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ReminderCard(
              title: 'Reflect on coding session',
              subtitle: 'Today, 6:00 PM',
              icon: Icons.code,
              isActive: true,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _ReminderCard(
              title: 'Morning health check',
              subtitle: 'Daily, 8:00 AM',
              icon: Icons.favorite_border,
              isActive: true,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _ReminderCard(
              title: 'Weekly review summary',
              subtitle: 'Sundays, 10:00 AM',
              icon: Icons.summarize_outlined,
              isActive: false,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final ThemeData theme;

  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(20),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Switch(value: isActive, onChanged: (val) {}),
      ),
    );
  }
}
