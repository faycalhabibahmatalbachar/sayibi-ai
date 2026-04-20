import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_provider.dart';

/// Médias générés par l’IA et documents (PDF, Word, images, etc.) — alimenté par `GET /user/files`.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final files = p.files;
    final gen = files?['generated'];
    final docs = files?['documents'];
    final gList = gen is List ? gen : <dynamic>[];
    final dList = docs is List ? docs : <dynamic>[];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Fichiers générés par ChadGpt et documents joints.',
                style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 13),
              ),
            ),
          ),
          if (p.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            SliverToBoxAdapter(
              child: _sectionTitle('Générés par l’IA', gList.length),
            ),
            if (gList.isEmpty)
              SliverToBoxAdapter(child: _emptyHint('Aucun fichier généré pour l’instant.'))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _generatedTile(gList[i] as Map),
                    childCount: gList.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _sectionTitle('Documents', dList.length),
              ),
            ),
            if (dList.isEmpty)
              SliverToBoxAdapter(child: _emptyHint('Aucun document uploadé.'))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _documentTile(dList[i] as Map),
                    ),
                    childCount: dList.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 14),
      ),
    );
  }

  Widget _generatedTile(Map<dynamic, dynamic> row) {
    final type = (row['type'] ?? row['file_type'] ?? '').toString().toLowerCase();
    final name = (row['filename'] ?? row['name'] ?? 'Fichier').toString();
    final url = (row['url'] ?? row['public_url'] ?? '').toString();
    final isImage = type.contains('image') ||
        type == 'png' ||
        type == 'jpg' ||
        name.toLowerCase().endsWith('.png') ||
        name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.webp');

    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: url.startsWith('http')
            ? () async {
                final u = Uri.tryParse(url);
                if (u != null && await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: isImage && url.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.darkBackground,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _typeIcon(type, isImage: true),
                      )
                    : _typeIcon(type, isImage: isImage),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type, {required bool isImage}) {
    IconData icon;
    Color c = AppColors.primary;
    if (isImage) {
      icon = Icons.image_outlined;
    } else if (type.contains('pdf') || type.contains('doc')) {
      icon = Icons.picture_as_pdf_outlined;
      c = AppColors.error;
    } else if (type.contains('excel') || type.contains('xls')) {
      icon = Icons.table_chart_outlined;
      c = AppColors.success;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    return Container(
      color: AppColors.darkBackground,
      alignment: Alignment.center,
      child: Icon(icon, size: 42, color: c.withValues(alpha: 0.85)),
    );
  }

  Widget _documentTile(Map<dynamic, dynamic> row) {
    final name = (row['filename'] ?? row['name'] ?? 'Document').toString();
    final url = (row['url'] ?? row['storage_path'] ?? '').toString();
    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: AppColors.info),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
        ),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.darkTextTertiary),
        onTap: url.startsWith('http')
            ? () async {
                final u = Uri.tryParse(url);
                if (u != null && await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              }
            : null,
      ),
    );
  }
}
