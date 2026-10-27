import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'playlists_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    final item = state.selected;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Belum ada media yang dipilih.')),
      );
    }
    final favorite = state.favorites.contains(item.id);
    final repeatLabel = switch (state.repeat) {
      PreviewRepeat.off => 'Ulangi: mati',
      PreviewRepeat.one => 'Ulangi: satu lagu',
      PreviewRepeat.all => 'Ulangi: semua',
    };
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Tutup Now Playing',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'NOW PLAYING',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      letterSpacing: 1.7,
                                      color: SonoraColors.muted,
                                    ),
                              ),
                              Text(
                                'Preview pemutar',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Buka antrean',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PreviewScope(
                                state: state,
                                child: const QueueScreen(),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.queue_music_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: SonoraColors.primary.withValues(
                                alpha: .13,
                              ),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: MediaArtwork(
                          style: item.style,
                          dimension: (constraints.maxWidth - 72).clamp(
                            220.0,
                            340.0,
                          ),
                          radius: 24,
                          hero: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.artist,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: SonoraColors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: favorite
                              ? 'Hapus dari favorit'
                              : 'Tambahkan ke favorit',
                          onPressed: () => state.toggleFavorite(item.id),
                          icon: Icon(
                            favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favorite
                                ? SonoraColors.primary
                                : SonoraColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const PreviewNotice(compact: true),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Posisi simulasi, bukan posisi audio asli',
                      slider: true,
                      child: Slider(
                        value: state.position.clamp(
                          0,
                          item.duration.toDouble(),
                        ),
                        max: item.duration.toDouble(),
                        onChanged: state.seek,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          formatDuration(state.position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          formatDuration(item.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: state.shuffle ? 'Acak aktif' : 'Acak mati',
                          isSelected: state.shuffle,
                          onPressed: state.toggleShuffle,
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: state.shuffle
                                ? SonoraColors.primary
                                : SonoraColors.muted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Lagu sebelumnya',
                          iconSize: 32,
                          onPressed: state.previous,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: IconButton.filled(
                            tooltip: state.previewMode
                                ? 'Tentang simulasi pemutaran'
                                : state.isPlaying
                                ? 'Jeda simulasi'
                                : 'Putar simulasi',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(68, 68),
                              maximumSize: const Size(68, 68),
                              shape: const CircleBorder(),
                              backgroundColor: SonoraColors.primary,
                              foregroundColor: const Color(0xFF171024),
                            ),
                            onPressed: () {
                              if (state.previewMode) {
                                showAppMessage(
                                  context,
                                  'Simulasi UI aktif: tidak ada audio yang diputar. Backend media belum tersedia.',
                                );
                              } else {
                                showAppMessage(
                                  context,
                                  'Playback asli belum tersedia pada tahap frontend.',
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 38,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Lagu berikutnya',
                          iconSize: 32,
                          onPressed: state.next,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        IconButton(
                          tooltip: repeatLabel,
                          isSelected: state.repeat != PreviewRepeat.off,
                          onPressed: state.cycleRepeat,
                          icon: Icon(
                            state.repeat == PreviewRepeat.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: state.repeat == PreviewRepeat.off
                                ? SonoraColors.muted
                                : SonoraColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Volume simulasi',
                          onPressed: () =>
                              state.setVolume(state.volume == 0 ? .72 : 0),
                          icon: Icon(
                            state.volume == 0
                                ? Icons.volume_off_outlined
                                : Icons.volume_down_outlined,
                            color: SonoraColors.muted,
                          ),
                        ),
                        Expanded(
                          child: Semantics(
                            label:
                                'Volume simulasi, belum mengontrol perangkat',
                            slider: true,
                            child: Slider(
                              value: state.volume,
                              onChanged: state.setVolume,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Volume penuh pada simulasi',
                          onPressed: () => state.setVolume(1),
                          icon: const Icon(
                            Icons.volume_up_outlined,
                            color: SonoraColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              state.enqueue(item.id);
                              showAppMessage(
                                context,
                                'Ditambahkan ke antrean preview.',
                              );
                            },
                            icon: const Icon(Icons.add_to_queue_outlined),
                            label: const Text('Antrean'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showAddToPlaylist(context, item),
                            icon: const Icon(Icons.playlist_add_rounded),
                            label: const Text('Playlist'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kontrol seek dan volume hanya mengubah nilai preview.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    final queue = state.queue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean'),
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              tooltip: 'Hapus seluruh antrean',
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.clear_all_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PreviewNotice(compact: true),
            ),
            if (state.selected != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dipilih saat ini',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MediaListTile(
                  item: state.selected!,
                  onTap: () {},
                  trailing: const Equalizer(animate: false),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Divider(),
              ),
            ],
            Expanded(
              child: queue.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.queue_music_rounded,
                              size: 44,
                              color: SonoraColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Antrean masih kosong',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan lagu melalui menu di Library atau Now Playing.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: SonoraColors.muted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: queue.length,
                      onReorderItem: state.reorderQueue,
                      itemBuilder: (context, index) {
                        final song = queue[index];
                        return Padding(
                          key: ValueKey('$index-${song.id}'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: MediaListTile(
                            item: song,
                            onTap: () => state.select(song),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Hapus ${song.title} dari antrean',
                                  onPressed: () =>
                                      state.removeFromQueueAt(index),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: SonoraColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    final state = PreviewScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan antrean?'),
        content: const Text(
          'Semua lagu berikutnya akan dihapus dari antrean preview. Media tidak dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              state.clearQueue();
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}
