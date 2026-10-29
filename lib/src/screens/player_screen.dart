import 'package:flutter/material.dart';

import '../app_state.dart';
import '../artwork.dart';
import '../media/media_item.dart';
import '../playback/notification_permission.dart';
import '../theme.dart';
import '../widgets/shared.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    final item = state.selected;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Belum ada media yang dipilih.')),
      );
    }
    final favorite = state.favorites.contains(item.id);
    final repeatLabel = switch (state.repeat) {
      SonoraRepeat.off => 'Ulangi: mati',
      SonoraRepeat.one => 'Ulangi: satu lagu',
      SonoraRepeat.all => 'Ulangi: semua',
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
                          child: Text(
                            'NOW PLAYING',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  letterSpacing: 1.7,
                                  color: SonoraColors.muted,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Buka antrean',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SonoraScope(
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
                        child: MediaArtwork.forItem(
                          item,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                    _SeekBar(item: item),
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
                            tooltip: state.isPlaying ? 'Jeda' : 'Putar',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(68, 68),
                              maximumSize: const Size(68, 68),
                              shape: const CircleBorder(),
                              backgroundColor: SonoraColors.primary,
                              foregroundColor: const Color(0xFF171024),
                            ),
                            onPressed: () async {
                              await ensureNotificationPermission();
                              await state.togglePlay();
                            },
                            icon: Icon(
                              state.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
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
                          isSelected: state.repeat != SonoraRepeat.off,
                          onPressed: state.cycleRepeat,
                          icon: Icon(
                            state.repeat == SonoraRepeat.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: state.repeat == SonoraRepeat.off
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
                          tooltip: state.volume == 0
                              ? 'Nyalakan suara'
                              : 'Bisukan',
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
                          child: Slider(
                            value: state.volume,
                            onChanged: state.setVolume,
                            semanticFormatterCallback: (value) =>
                                'Volume ${(value * 100).round()} persen',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Volume penuh',
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
                            onPressed: () => state.enqueue(item.id),
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
                    if (!item.available) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Berkas media ini tidak ditemukan. Impor ulang atau '
                        'hapus dari library.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: SonoraColors.warning),
                      ),
                    ],
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

/// Seek bar yang mengikuti posisi pemutar tanpa membangun ulang seluruh layar.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.item});
  final MediaItem item;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: state.positionNotifier,
      builder: (context, position, _) {
        final total = state.duration ?? widget.item.durationValue;
        final max = total.inMilliseconds.toDouble();
        final value = (_dragValue ?? position.inMilliseconds.toDouble()).clamp(
          0.0,
          max <= 0 ? 1.0 : max,
        );
        return Column(
          children: [
            Slider(
              value: max <= 0 ? 0 : value,
              max: max <= 0 ? 1 : max,
              onChanged: max <= 0
                  ? null
                  : (next) => setState(() => _dragValue = next),
              onChangeEnd: max <= 0
                  ? null
                  : (next) async {
                      setState(() => _dragValue = null);
                      await state.seek(Duration(milliseconds: next.round()));
                    },
              semanticFormatterCallback: (next) => formatDuration(next ~/ 1000),
            ),
            Row(
              children: [
                Text(
                  formatDuration(value ~/ 1000),
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
        );
      },
    );
  }
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
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
                  trailing: Equalizer(animate: state.isPlaying),
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
                              'Tambahkan lagu melalui menu di Library atau '
                              'Now Playing. Antrean tersimpan di perangkat.',
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
                            onTap: () => state.playItem(song),
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
    final state = SonoraScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan antrean?'),
        content: const Text(
          'Semua lagu berikutnya akan dihapus dari antrean. Media di library '
          'tidak dihapus.',
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
