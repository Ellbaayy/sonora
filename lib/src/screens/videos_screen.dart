import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../app_state.dart';
import '../artwork.dart';
import '../media/media_item.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;
  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    if (state.videos.isEmpty) {
      return Column(
        children: [
          ScreenHeader(
            title: 'Video',
            action: IconButton(
              tooltip: 'Impor video',
              onPressed: () => runMediaImport(context, MediaKind.video),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          Expanded(
            child: EmptyLibrary(
              kind: MediaKind.video,
              onImport: () => runMediaImport(context, MediaKind.video),
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
            onPressed: () => runMediaImport(context, MediaKind.video),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
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
                onTap: () => openVideoPlayer(context, video),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaArtwork.forItem(
                            video,
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
                      video.available
                          ? 'Video lokal'
                          : 'Berkas tidak ditemukan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: video.available
                            ? SonoraColors.muted
                            : SonoraColors.warning,
                      ),
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
            onPressed: () => runMediaImport(context, MediaKind.video),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Impor video dari perangkat'),
          ),
        ),
      ],
    );
  }
}

/// Membuka pemutar video. Musik dijeda lebih dulu agar hanya satu sumber audio
/// yang aktif (PRD bagian 8.8).
Future<void> openVideoPlayer(BuildContext context, MediaItem video) async {
  final state = SonoraScope.of(context);
  if (!video.available) {
    showAppMessage(
      context,
      'Berkas video tidak ditemukan. Impor ulang atau hapus dari library.',
    );
    return;
  }
  await state.pausePlayback();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SonoraScope(
        state: state,
        child: VideoPlayerScreen(video: video),
      ),
    ),
  );
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.video});
  final MediaItem video;
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? controller;
  bool initializing = true;
  String? error;
  bool fullscreen = false;
  double volume = 1;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final file = File(widget.video.uri);
    if (!await file.exists()) {
      setState(() {
        initializing = false;
        error = 'Berkas video tidak ditemukan di penyimpanan aplikasi.';
      });
      return;
    }
    final created = VideoPlayerController.file(file);
    controller = created;
    try {
      await created.initialize();
      await created.setVolume(volume);
      await created.play();
      if (!mounted) return;
      setState(() => initializing = false);
      created.addListener(_onTick);
    } catch (onError) {
      if (!mounted) return;
      setState(() {
        initializing = false;
        error =
            'Video tidak dapat diputar. Format berkas mungkin tidak didukung.';
      });
    }
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller?.removeListener(_onTick);
    controller?.dispose();
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  Future<void> _toggleFullscreen() async {
    setState(() => fullscreen = !fullscreen);
    if (fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = controller;
    final ready = player != null && player.value.isInitialized;
    final position = ready ? player.value.position : Duration.zero;
    final total = ready ? player.value.duration : Duration.zero;
    return Scaffold(
      backgroundColor: SonoraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (!fullscreen)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Kembali ke library video',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: ready && player.value.aspectRatio > 0
                      ? player.value.aspectRatio
                      : 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(fullscreen ? 0 : 16),
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (ready)
                            VideoPlayer(player)
                          else
                            const ColoredBox(
                              color: Colors.black,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (error != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: SonoraColors.warning,
                                  ),
                                ),
                              ),
                            ),
                          if (ready)
                            Align(
                              alignment: Alignment.center,
                              child: IconButton(
                                tooltip: player.value.isPlaying
                                    ? 'Jeda video'
                                    : 'Putar video',
                                onPressed: () {
                                  player.value.isPlaying
                                      ? player.pause()
                                      : player.play();
                                  setState(() {});
                                },
                                icon: Icon(
                                  player.value.isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  size: 72,
                                  color: SonoraColors.text.withValues(
                                    alpha: .92,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!fullscreen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDuration(total.inSeconds),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (ready) ...[
                      Slider(
                        value: position.inMilliseconds
                            .clamp(0, total.inMilliseconds)
                            .toDouble(),
                        max: total.inMilliseconds <= 0
                            ? 1
                            : total.inMilliseconds.toDouble(),
                        onChanged: total.inMilliseconds <= 0
                            ? null
                            : (value) => player.seekTo(
                                Duration(milliseconds: value.round()),
                              ),
                      ),
                      Row(
                        children: [
                          Text(
                            formatDuration(position.inSeconds),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            formatDuration(total.inSeconds),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Volume video',
                          onPressed: () {
                            setState(() => volume = volume == 0 ? 1 : 0);
                            player?.setVolume(volume);
                          },
                          icon: Icon(
                            volume == 0
                                ? Icons.volume_off_outlined
                                : Icons.volume_up_outlined,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: volume,
                            onChanged: (value) {
                              setState(() => volume = value);
                              player?.setVolume(value);
                            },
                            semanticFormatterCallback: (value) =>
                                'Volume video ${(value * 100).round()} persen',
                          ),
                        ),
                        IconButton(
                          tooltip: fullscreen
                              ? 'Keluar layar penuh'
                              : 'Layar penuh',
                          onPressed: _toggleFullscreen,
                          icon: Icon(
                            fullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (initializing)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Menyiapkan video…'),
              ),
          ],
        ),
      ),
    );
  }
}
