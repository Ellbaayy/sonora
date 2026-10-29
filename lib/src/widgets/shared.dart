import 'package:flutter/material.dart';

import '../app_state.dart';
import '../artwork.dart';
import '../data/models.dart';
import '../media/media_item.dart';
import '../theme.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class LocalSearchField extends StatelessWidget {
  const LocalSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Cari judul, artis, atau album',
    this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class MediaListTile extends StatelessWidget {
  const MediaListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onMenu,
    this.trailing,
  });
  final MediaItem item;
  final VoidCallback onTap;
  final VoidCallback? onMenu;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    final isSelected = state.selected?.id == item.id;
    final subtitle = item.available
        ? '${item.artist}  •  ${formatDuration(item.duration)}'
        : 'Berkas tidak ditemukan  •  impor ulang atau hapus';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              MediaArtwork.forItem(item, dimension: 56, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? SonoraColors.primary
                            : SonoraColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: SonoraColors.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (!item.available) ...[
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: SonoraColors.warning,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: item.available
                                      ? SonoraColors.muted
                                      : SonoraColors.warning,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              trailing ??
                  IconButton(
                    tooltip: 'Opsi ${item.title}',
                    onPressed: onMenu,
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class HorizontalMediaCard extends StatelessWidget {
  const HorizontalMediaCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 148,
  });
  final MediaItem item;
  final VoidCallback onTap;
  final double width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaArtwork.forItem(item, dimension: width, radius: 16),
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              item.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.kind, required this.onImport});
  final MediaKind kind;
  final VoidCallback onImport;
  @override
  Widget build(BuildContext context) {
    final isVideo = kind == MediaKind.video;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const MediaIllustration(dimension: 164),
              const SizedBox(height: 20),
              Text(
                isVideo
                    ? 'Video kamu, tanpa streaming.'
                    : 'Koleksimu. Tetap milikmu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                isVideo
                    ? 'Impor MP4 dari perangkat dan nikmati koleksi tanpa koneksi internet.'
                    : 'Impor musik dari perangkat. Berkas asli tetap di tempatnya, tanpa unggah ke server.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: SonoraColors.muted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add_rounded),
                label: Text(isVideo ? 'Impor video' : 'Impor musik'),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: SonoraColors.muted,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Media tetap lokal',
                    style: TextStyle(fontSize: 12, color: SonoraColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
}

/// Menampilkan pesan tertunda dari state (kesalahan simpan, berkas hilang, dan
/// sejenisnya) sekali saja.
void showPendingNotice(BuildContext context) {
  final state = SonoraScope.of(context);
  final notice = state.takeNotice();
  if (notice != null) showAppMessage(context, notice);
}

/// Menjalankan alur impor lengkap: dialog progres, ringkasan hasil, dan pesan
/// kesalahan yang spesifik.
Future<void> runMediaImport(BuildContext context, MediaKind kind) async {
  final state = SonoraScope.of(context);
  if (state.importing) return;
  final label = kind == MediaKind.audio ? 'musik' : 'video';
  BuildContext? dialogContext;
  final dialogReady = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) {
      dialogContext = sheetContext;
      return AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final progress = state.importProgress;
          final total = progress?.total ?? 0;
          final processed = progress?.processed ?? 0;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text('Mengimpor $label'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: total == 0 ? null : (processed / total).clamp(0, 1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    progress?.fileName ?? 'Membuka pemilih berkas…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$processed dari $total berkas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Berkas disalin ke penyimpanan aplikasi agar tetap dapat '
                    'diputar setelah aplikasi ditutup. Berkas asli tidak diubah.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  await Future<void>.delayed(Duration.zero);
  final report = await state.importMedia(kind);
  if (dialogContext != null && dialogContext!.mounted) {
    Navigator.of(dialogContext!).pop();
  }
  await dialogReady;
  if (!context.mounted) return;
  final notice = state.takeNotice();
  if (notice != null) {
    showAppMessage(context, notice);
    return;
  }
  if (report == null || report.isEmpty) {
    showAppMessage(context, 'Tidak ada berkas yang dipilih.');
    return;
  }
  await showImportSummary(context, report);
}

/// Ringkasan hasil impor sesuai PRD bagian 8.4.
Future<void> showImportSummary(
  BuildContext context,
  ImportReport report,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Impor selesai'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              icon: Icons.check_circle_outline_rounded,
              color: SonoraColors.success,
              text: '${report.importedCount} berkas ditambahkan',
            ),
            _SummaryRow(
              icon: Icons.copy_all_outlined,
              color: SonoraColors.muted,
              text: '${report.duplicateCount} duplikat dilewati',
            ),
            _SummaryRow(
              icon: Icons.error_outline_rounded,
              color: report.rejectedCount == 0
                  ? SonoraColors.muted
                  : SonoraColors.warning,
              text: '${report.rejectedCount} berkas tidak didukung',
            ),
            if (report.rejected.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final outcome in report.rejected.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${outcome.fileName}: ${outcome.reason ?? 'tidak didukung'}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Menu opsi media yang dipakai Home, Library, dan daftar lainnya.
Future<void> showMediaOptions(BuildContext context, MediaItem item) async {
  final state = SonoraScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              leading: MediaArtwork.forItem(item, dimension: 56),
              title: Text(item.title, maxLines: 2),
              subtitle: Text(item.artist),
            ),
            const Divider(),
            if (item.kind == MediaKind.audio) ...[
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Putar sekarang'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  state.playItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Tambahkan ke antrean'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  state.enqueue(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Tambahkan ke playlist'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAddToPlaylist(context, item);
                },
              ),
            ],
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: SonoraColors.danger,
              ),
              title: const Text(
                'Hapus dari library',
                style: TextStyle(color: SonoraColors.danger),
              ),
              subtitle: const Text(
                'Salinan aplikasi dihapus, berkas asli tetap',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                confirmRemoveFromLibrary(context, item);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> confirmRemoveFromLibrary(
  BuildContext context,
  MediaItem item,
) async {
  final state = SonoraScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus dari library?'),
      content: Text(
        '“${item.title}” akan dihapus dari library SONORA beserta salinan yang '
        'dibuat saat impor. Berkas asli di perangkat tidak dihapus.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: SonoraColors.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await state.removeFromLibrary(item.id);
  if (!context.mounted) return;
  showAppMessage(context, 'Media dihapus dari library.');
}

/// Dialog menambahkan satu media ke playlist yang sudah ada.
Future<void> showAddToPlaylist(BuildContext context, MediaItem item) async {
  final state = SonoraScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Tambahkan “${item.title}” ke',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (state.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Belum ada playlist. Buat playlist terlebih dahulu.',
                ),
              ),
            ...state.playlists.map((playlist) {
              final exists = playlist.trackIds.contains(item.id);
              return ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(playlist.name),
                subtitle: Text(
                  exists
                      ? 'Sudah ada di playlist'
                      : '${playlist.trackIds.length} lagu',
                ),
                trailing: exists
                    ? const Icon(
                        Icons.check_rounded,
                        color: SonoraColors.success,
                      )
                    : const Icon(Icons.add_rounded),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (exists) {
                    showAppMessage(
                      context,
                      'Lagu sudah ada di playlist tersebut.',
                    );
                    return;
                  }
                  await state.addToPlaylist(playlist.id, item.id);
                  if (!context.mounted) return;
                  showPendingNotice(context);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}
