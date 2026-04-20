import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

class PlusMenuSheet extends StatefulWidget {
  const PlusMenuSheet({
    super.key,
    required this.webSearchEnabled,
    required this.documentMode,
    required this.createMode,
    required this.uploadedDocName,
    required this.createType,
    required this.agentModeEnabled,
    required this.onWebSearchToggled,
    required this.onDocumentUploadRequested,
    required this.onDocumentUploaded,
    required this.onDocumentRemoved,
    required this.onCreateToggled,
    required this.onAgentModeToggled,
    required this.onAlarmsRequested,
  });

  final bool webSearchEnabled;
  final bool documentMode;
  final bool createMode;
  final String? uploadedDocName;
  final String createType;
  final bool agentModeEnabled;
  final void Function(bool value) onWebSearchToggled;
  final Future<String?> Function(PlatformFile file) onDocumentUploadRequested;
  final void Function(String docId, String docName) onDocumentUploaded;
  final VoidCallback onDocumentRemoved;
  final void Function(bool enabled, String type) onCreateToggled;
  final void Function(bool value) onAgentModeToggled;
  final VoidCallback onAlarmsRequested;

  @override
  State<PlusMenuSheet> createState() => _PlusMenuSheetState();
}

class _PlusMenuSheetState extends State<PlusMenuSheet> {
  bool _showCreateOptions = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.chatFeaturesTitle,
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildWebSearchOption(),
              const SizedBox(height: 12),
              _buildAgentModeOption(),
              const SizedBox(height: 12),
              _buildDocumentOption(),
              const SizedBox(height: 12),
              _buildCreateOption(),
              const SizedBox(height: 12),
              _buildAlarmOption(),
              if (_showCreateOptions) ...[
                const SizedBox(height: 16),
                _buildCreateSubOptions(),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSearchOption() {
    final isActive = widget.webSearchEnabled;
    return _buildOptionTile(
      icon: Icons.travel_explore_rounded,
      emoji: '🔍',
      title: 'Recherche Web',
      subtitle: isActive
          ? 'L\'IA consulte internet en temps réel'
          : 'Activer pour chercher sur internet',
      isActive: isActive,
      activeColor: AppColors.info,
      trailing: Switch(
        value: isActive,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          widget.onWebSearchToggled(v);
          Navigator.pop(context);
        },
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildAgentModeOption() {
    final isActive = widget.agentModeEnabled;
    return _buildOptionTile(
      icon: Icons.touch_app_rounded,
      emoji: '⚡',
      title: 'Mode actions',
      subtitle: isActive
          ? 'SMS, appels, rappels — avec confirmation'
          : 'Actions sur l’appareil (recommandé sur mobile)',
      isActive: isActive,
      activeColor: AppColors.primary,
      trailing: Switch(
        value: isActive,
        onChanged: (v) {
          HapticFeedback.mediumImpact();
          widget.onAgentModeToggled(v);
          Navigator.pop(context);
        },
      ),
    ).animate().fadeIn(delay: 75.ms, duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildDocumentOption() {
    final isActive = widget.documentMode;
    return _buildOptionTile(
      icon: Icons.description_rounded,
      emoji: '📄',
      title: 'Analyser Document',
      subtitle: isActive
          ? (widget.uploadedDocName ?? 'Document chargé')
          : 'PDF, Word, Excel, Image',
      isActive: isActive,
      activeColor: AppColors.warning,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onDocumentRemoved();
                Navigator.pop(context);
              },
            ),
          if (!isActive)
            ElevatedButton(
              onPressed: _pickDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                foregroundColor: AppColors.warning,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Choisir',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildCreateOption() {
    final isActive = widget.createMode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showCreateOptions = !_showCreateOptions);
      },
      child: _buildOptionTile(
        icon: Icons.auto_awesome_rounded,
        emoji: '✨',
        title: 'Créer un Document',
        subtitle: isActive
            ? 'Mode: ${_getCreateLabel(widget.createType)}'
            : 'CV, Lettre, Rapport, Excel',
        isActive: isActive,
        activeColor: AppColors.accent,
        trailing: AnimatedRotation(
          turns: _showCreateOptions ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.darkTextTertiary,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildAlarmOption() {
    return _buildOptionTile(
      icon: Icons.alarm_rounded,
      emoji: '⏰',
      title: 'Alarmes',
      subtitle: 'Créer, modifier, supprimer et voir les alarmes',
      isActive: false,
      activeColor: AppColors.success,
      trailing: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          widget.onAlarmsRequested();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success.withValues(alpha: 0.18),
          foregroundColor: AppColors.success,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Ouvrir',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ).animate().fadeIn(delay: 175.ms, duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildCreateSubOptions() {
    final createTypes = [
      _CreateType(
        id: 'cv',
        emoji: '👤',
        label: 'CV Professionnel',
        desc: 'Avec design, sections, photo',
        color: const Color(0xFF10B981),
      ),
      _CreateType(
        id: 'letter',
        emoji: '✉️',
        label: 'Lettre de Motivation',
        desc: 'Formatée et personnalisée',
        color: const Color(0xFF3B82F6),
      ),
      _CreateType(
        id: 'report',
        emoji: '📊',
        label: 'Rapport PDF',
        desc: 'Structure pro avec graphiques',
        color: const Color(0xFF8B5CF6),
      ),
      _CreateType(
        id: 'excel',
        emoji: '📈',
        label: 'Tableur Excel',
        desc: 'Formules, tableaux, graphiques',
        color: const Color(0xFF059669),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir le type de document',
            style: TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // Plus de hauteur pour libellés / descriptions sur 2 lignes
              childAspectRatio: 1.35,
            ),
            itemCount: createTypes.length,
            itemBuilder: (context, i) {
              final ct = createTypes[i];
              final isSelected = widget.createMode && widget.createType == ct.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onCreateToggled(true, ct.id);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ct.color.withValues(alpha: 0.2)
                        : ct.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? ct.color.withValues(alpha: 0.5)
                          : ct.color.withValues(alpha: 0.15),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ct.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ct.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? ct.color : AppColors.darkTextPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              ct.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.darkTextTertiary,
                                fontSize: 9,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (i * 50).ms)
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, duration: 200.ms);
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required bool isActive,
    required Color activeColor,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.08)
            : AppColors.darkBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? activeColor.withValues(alpha: 0.3) : AppColors.darkBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? activeColor : AppColors.darkTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppStrings.chatActive,
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextTertiary,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'jpg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final name = file.name;
      final uploadedDocId = await widget.onDocumentUploadRequested(file);
      if (uploadedDocId == null || uploadedDocId.isEmpty) return;
      widget.onDocumentUploaded(uploadedDocId, name);
      if (mounted) Navigator.pop(context);
    }
  }

  String _getCreateLabel(String type) {
    const m = {
      'cv': 'CV',
      'letter': 'Lettre',
      'report': 'Rapport',
      'excel': 'Excel',
    };
    return m[type] ?? 'Document';
  }
}

class _CreateType {
  const _CreateType({
    required this.id,
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
  });

  final String id;
  final String emoji;
  final String label;
  final String desc;
  final Color color;
}
