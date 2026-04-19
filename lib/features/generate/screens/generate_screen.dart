import 'package:flutter/material.dart';

import '../widgets/template_card.dart';

class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TemplateCard(
          title: 'CV professionnel',
          icon: Icons.badge_outlined,
          onTap: () {},
        ),
        TemplateCard(
          title: 'Lettre de motivation',
          icon: Icons.mail_outline,
          onTap: () {},
        ),
        TemplateCard(
          title: 'Rapport PDF',
          icon: Icons.picture_as_pdf_outlined,
          onTap: () {},
        ),
        TemplateCard(
          title: 'Tableur Excel',
          icon: Icons.table_chart_outlined,
          onTap: () {},
        ),
        TemplateCard(
          title: 'Présentation (bientôt)',
          icon: Icons.slideshow_outlined,
          onTap: () {},
        ),
      ],
    );
  }
}
