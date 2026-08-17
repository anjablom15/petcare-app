import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'coming_soon_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Grooming', 'icon': Icons.content_cut},
      {'title': 'Health', 'icon': Icons.favorite_outline},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: Icon(item['icon'] as IconData, color: AppColors.primary),
              title: Text(item['title'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ComingSoonScreen(
                      title: item['title'] as String,
                      icon: item['icon'] as IconData,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
