import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    if (!state.previewMode) {
      return Column(
        children: [
          const ScreenHeader(title: 'Video'),
          Expanded(
            child: EmptyLibrary(
              kind: MediaKind.video,
              onImport: () => showImportPreview(context, kind: MediaKind.video),
              onPreview: state.showPreview,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          title: 'Ruang video',
          subtitle: 'Koleksi visualmu, tetap offline.',
          action: IconButton(
            tooltip: 'Impor video',
            onPressed: () => showImportPreview(context, kind: MediaKind.video),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: PreviewNotice(compact: true),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: .8,
            ),
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final video = state.videos[index];
              return InkWell(
                onTap: () {
                  state.select(video);
                  onOpenPlayer();
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaArtwork(
                            style: video.style,
                            dimension: 300,
                            radius: 16,
                          ),
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: SonoraColors.background.withValues(
                                  alpha: .65,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: SonoraColors.text,
                                size: 28,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SonoraColors.background.withValues(
                                  alpha: .8,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatDuration(video.duration),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: SonoraColors.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview video',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () => showImportPreview(context, kind: MediaKind.video),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Impor MP4 dari perangkat'),
          ),
        ),
      ],
    );
  }
}

Future<void> openVideoPreview(BuildContext context, MediaItem video) async {
  final state = PreviewScope.of(context);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PreviewScope(
        state: state,
        child: VideoPreviewScreen(video: video),
      ),
    ),
  );
}

class VideoPreviewScreen extends StatelessWidget {
  const VideoPreviewScreen({super.key, required this.video});
  final MediaItem video;
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    return Scaffold(
      backgroundColor: SonoraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Kembali ke library video',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MediaArtwork(
                              style: video.style,
                              dimension: 640,
                              radius: 0,
                            ),
                            ColoredBox(
                              color: SonoraColors.background.withValues(
                                alpha: .2,
                              ),
                            ),
                            Center(
                              child: IconButton(
                                tooltip: 'Pratinjau kontrol video',
                                onPressed: () => showAppMessage(
                                  context,
                                  'Pemutaran MP4 belum terhubung. Ini hanya preview tampilan.',
                                ),
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 72,
                                  color: SonoraColors.text,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: SonoraColors.background.withValues(
                                    alpha: .8,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: SonoraColors.warning,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Preview tampilan • video belum diputar',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        video.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${formatDuration(video.duration)} • Video contoh',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: SonoraColors.muted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: state.position.clamp(0, video.duration.toDouble()),
                      max: video.duration.toDouble(),
                      onChanged: state.seek,
                    ),
                    Row(
                      children: [
                        Text(formatDuration(state.position)),
                        const Spacer(),
                        Text(formatDuration(video.duration)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Jeda preview video',
                          onPressed: () => showAppMessage(
                            context,
                            'Video engine belum tersedia pada tahap frontend.',
                          ),
                          icon: const Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          tooltip: 'Volume preview video',
                          onPressed: () => showAppMessage(
                            context,
                            'Kontrol volume tersedia sebagai slider pada layar musik. Video engine belum tersedia.',
                          ),
                          icon: const Icon(Icons.volume_up_outlined, size: 28),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          tooltip: 'Layar penuh belum tersedia',
                          onPressed: () => showAppMessage(
                            context,
                            'Fullscreen akan diaktifkan bersama video player asli.',
                          ),
                          icon: const Icon(Icons.fullscreen_rounded, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const PreviewNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
