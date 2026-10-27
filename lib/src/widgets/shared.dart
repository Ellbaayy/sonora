import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    if (!state.previewMode) return const SizedBox.shrink();
    return Semantics(
      label: 'Informasi status pratinjau',
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: SonoraColors.warning.withValues(alpha: .065),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SonoraColors.warning.withValues(alpha: .25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                color: SonoraColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pratinjau antarmuka',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: SonoraColors.warning),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Media dan perubahan hanya contoh, belum dibaca atau disimpan dari perangkat.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: SonoraColors.muted),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Lihat tampilan koleksi kosong',
                child: InkWell(
                  onTap: state.showEmptyLibrary,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: SonoraColors.warning,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    final state = PreviewScope.of(context);
    final isSelected = state.selected?.id == item.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              MediaArtwork(style: item.style, dimension: 56, radius: 12),
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
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: SonoraColors.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            '${item.artist}  •  ${formatDuration(item.duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
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
            MediaArtwork(style: item.style, dimension: width, radius: 16),
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

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    final item = state.selected;
    if (item == null || item.kind != MediaKind.audio) {
      return const SizedBox.shrink();
    }
    return Material(
      color: SonoraColors.raised,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: SonoraColors.border),
              bottom: BorderSide(color: SonoraColors.border),
            ),
          ),
          child: Row(
            children: [
              MediaArtwork(style: item.style, dimension: 46, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dipilih • belum memutar audio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: state.isPlaying ? 'Jeda simulasi' : 'Putar simulasi',
                onPressed: state.previewMode ? onOpen : state.togglePlay,
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: SonoraColors.primary,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({
    super.key,
    required this.kind,
    required this.onImport,
    this.onPreview,
  });
  final MediaKind kind;
  final VoidCallback onImport;
  final VoidCallback? onPreview;
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
                    : 'Impor musik dari perangkat. File asli tetap di tempatnya, tanpa unggah ke server.',
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
              const SizedBox(height: 12),
              if (onPreview != null)
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat tampilan contoh'),
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

Future<void> showImportPreview(
  BuildContext context, {
  required MediaKind kind,
}) async {
  var selected = kind;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MediaIllustration(dimension: 116),
              const SizedBox(height: 8),
              Text(
                'Impor dari perangkat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih jenis media. Tidak ada file yang diunggah.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: SonoraColors.muted),
              ),
              const SizedBox(height: 24),
              SegmentedButton<MediaKind>(
                segments: const [
                  ButtonSegment(
                    value: MediaKind.audio,
                    label: Text('Musik'),
                    icon: Icon(Icons.music_note_rounded),
                  ),
                  ButtonSegment(
                    value: MediaKind.video,
                    label: Text('Video'),
                    icon: Icon(Icons.videocam_outlined),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) =>
                    setState(() => selected = selection.first),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SonoraColors.warning.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Integrasi file picker belum tersedia pada tahap frontend. Tidak ada file yang akan dibaca.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Pilih file dari perangkat'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    showAppMessage(
      context,
      'File picker belum terhubung. Tidak ada media yang diimpor.',
    );
  }
}
