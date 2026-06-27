import 'package:flutter/material.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/analytics_service.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search Vault')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by keyword, tag, or time...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () {},
                  ),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    try {
                      sl<AnalyticsService>().incrementSearchCount();
                    } catch (_) {}
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Searches',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SearchTag(label: 'Coding session'),
                  _SearchTag(label: 'June 2026'),
                  _SearchTag(label: '#Fitness'),
                  _SearchTag(label: 'Park run'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchTag extends StatelessWidget {
  final String label;

  const _SearchTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
