import 'package:flutter/material.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
