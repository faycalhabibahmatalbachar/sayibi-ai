import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class ModelSelectorSheet extends ConsumerWidget {
  const ModelSelectorSheet({super.key});

  static const _models = [
    _ModelItem(
      id: 'auto',
      emoji: '⚡',
      name: 'Auto',
      tagline: 'Sélection automatique intelligente',
      desc: 'ChadGpt choisit le meilleur modèle pour chaque question.',
      color: Color(0xFF6C63FF),
      capabilities: ['Chat', 'Analyse', 'Code', 'Création'],
    ),
    _ModelItem(
      id: 'sayibi-reflexion',
      emoji: '🧠',
      name: 'ChadGpt Réflexion',
      tagline: 'Notre modèle le plus intelligent',
      desc:
          'Raisonnement profond pour les problèmes complexes, maths, logique et analyses stratégiques.',
      color: Color(0xFF8B5CF6),
      capabilities: ['Raisonnement', 'Maths', 'Logique', 'Recherche'],
    ),
    _ModelItem(
      id: 'sayibi-images',
      emoji: '🎨',
      name: 'ChadGpt Images',
      tagline: 'Crée des images depuis vos mots',
      desc:
          'Génération d\'images professionnelles, illustrations et visuels depuis une description texte.',
      color: Color(0xFFEC4899),
      capabilities: ['Génération', 'Illustration', 'Design'],
      isNew: true,
    ),
    _ModelItem(
      id: 'sayibi-nadirx',
      emoji: '📊',
      name: 'ChadGpt NadirX',
      tagline: 'Expert analyse & documents',
      desc:
          'Analyse de contrats, factures, données financières et extraction d\'informations précises.',
      color: Color(0xFF00D4AA),
      capabilities: ['Analyse docs', 'OCR', 'Tableaux', 'Données'],
    ),
    _ModelItem(
      id: 'sayibi-voix',
      emoji: '🎙️',
      name: 'ChadGpt Voix',
      tagline: 'Optimisé pour les conversations vocales',
      desc:
          'Réponses rapides et naturelles. Idéal pour l\'assistant vocal mains-libres.',
      color: Color(0xFFF59E0B),
      capabilities: ['Vocal', 'Rapide', 'Concis'],
    ),
    _ModelItem(
      id: 'sayibi-code',
      emoji: '💻',
      name: 'ChadGpt Code',
      tagline: 'Développeur IA expert',
      desc:
          'Génération, débogage et explication de code en +50 langages de programmation.',
      color: Color(0xFF3B82F6),
      capabilities: ['Code', 'Debug', 'Expliquer', 'Refactoring'],
    ),
    _ModelItem(
      id: 'sayibi-creation',
      emoji: '✨',
      name: 'ChadGpt Création',
      tagline: 'CV, Lettres & Rapports Pro',
      desc:
          'Génère des documents professionnels avec design, mise en page et formatage avancé.',
      color: Color(0xFF10B981),
      capabilities: ['CV', 'Lettre', 'Rapport', 'Excel'],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(chatProvider).selectedModel;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Modèles',
                    style: TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.darkTextTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                itemCount: _models.length,
                itemBuilder: (context, i) {
                  final model = _models[i];
                  final isSelected = selectedModel == model.id;
                  return _buildModelCard(
                    context,
                    ref,
                    model,
                    isSelected,
                    i,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    WidgetRef ref,
    _ModelItem model,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(chatProvider.notifier).selectModel(model.id);
        Navigator.pop(context, model.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? model.color.withValues(alpha: 0.1)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? model.color.withValues(alpha: 0.5) : AppColors.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: model.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(model.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.name,
                          style: TextStyle(
                            color: isSelected ? model.color : AppColors.darkTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (model.isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    model.tagline,
                    style: TextStyle(
                      color: isSelected
                          ? model.color.withValues(alpha: 0.85)
                          : AppColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('selected'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: model.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : const SizedBox(width: 28, height: 28),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _ModelItem {
  const _ModelItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.desc,
    required this.color,
    required this.capabilities,
    this.isNew = false,
  });

  final String id;
  final String emoji;
  final String name;
  final String tagline;
  final String desc;
  final Color color;
  final List<String> capabilities;
  final bool isNew;
}
