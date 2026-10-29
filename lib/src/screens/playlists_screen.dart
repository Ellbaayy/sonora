import 'package:flutter/material.dart';

import '../app_state.dart';
import '../artwork.dart';
import '../media/media_item.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    if (state.songs.isEmpty) {
      return Column(
        children: [
          const ScreenHeader(
            title: 'Playlist',
            subtitle: 'Suasana yang berbeda, satu koleksi.',
          ),
          Expanded(
            child: EmptyLibrary(
              kind: MediaKind.audio,
              onImport: () => runMediaImport(context, MediaKind.audio),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        ScreenHeader(
          title: 'Playlist',
          subtitle: 'Suasana yang berbeda, satu koleksi.',
          action: IconButton(
            tooltip: 'Buat playlist baru',
            onPressed: () => showPlaylistNameDialog(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        if (state.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.queue_music_outlined,
                      color: SonoraColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada playlist',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelompokkan lagu sesuai suasana. Playlist tersimpan di '
                      'perangkat ini.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => showPlaylistNameDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Buat playlist baru'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ...state.playlists.map((playlist) {
            final songs = state.songsInPlaylist(playlist.id);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SonoraScope(
                        state: state,
                        child: PlaylistDetailScreen(
                          playlistId: playlist.id,
                          onOpenPlayer: onOpenPlayer,
                        ),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _PlaylistMosaic(songs: songs),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${songs.length} lagu',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Buka playlist',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: SonoraColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Opsi playlist ${playlist.name}',
                          onPressed: () => _playlistOptions(context, playlist),
                          icon: const Icon(Icons.more_vert_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => showPlaylistNameDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat playlist baru'),
            ),
          ),
        ],
      ],
    );
  }

  void _playlistOptions(BuildContext context, Playlist playlist) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                playlist.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Ubah nama playlist'),
              onTap: () {
                Navigator.pop(sheetContext);
                showPlaylistNameDialog(context, playlist: playlist);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: SonoraColors.danger,
              ),
              title: const Text(
                'Hapus playlist',
                style: TextStyle(color: SonoraColors.danger),
              ),
              subtitle: const Text('Tidak menghapus media atau file asli'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, playlist);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Playlist playlist) {
    final state = SonoraScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus playlist?'),
        content: Text(
          '“${playlist.name}” akan dihapus. Media di dalamnya tetap ada di '
          'library dan file asli tidak dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SonoraColors.danger),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await state.deletePlaylist(playlist.id);
              if (!context.mounted) return;
              showAppMessage(context, 'Playlist dihapus.');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistMosaic extends StatelessWidget {
  const _PlaylistMosaic({required this.songs});
  final List<MediaItem> songs;
  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: SonoraColors.raised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.queue_music_rounded,
          color: SonoraColors.primary,
        ),
      );
    }
    return SizedBox(
      width: 76,
      height: 76,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (index) => MediaArtwork.forItem(
            songs[index % songs.length],
            dimension: 38,
            radius: index == 0 ? 12 : 4,
          ),
        ),
      ),
    );
  }
}

Future<void> showPlaylistNameDialog(
  BuildContext context, {
  Playlist? playlist,
}) async {
  final state = SonoraScope.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _PlaylistNameDialog(
      initialName: playlist?.name ?? '',
      isEditing: playlist != null,
      onSave: (name) => playlist == null
          ? state.createPlaylist(name)
          : state.renamePlaylist(playlist.id, name),
    ),
  );
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.initialName,
    required this.isEditing,
    required this.onSave,
  });

  final String initialName;
  final bool isEditing;
  final Future<String?> Function(String name) onSave;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController controller;
  String? error;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    final result = await widget.onSave(controller.text);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        error = result;
        saving = false;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Ubah nama playlist' : 'Playlist baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nama playlist',
              hintText: 'Misalnya, Teman perjalanan',
              errorText: error,
            ),
            onSubmitted: (_) => save(),
          ),
          const SizedBox(height: 8),
          Text(
            'Playlist disimpan di perangkat ini.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.onOpenPlayer,
  });
  final String playlistId;
  final VoidCallback onOpenPlayer;
  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    final playlist = state.playlistById(playlistId);
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Playlist tidak tersedia.')),
      );
    }
    final songs = state.songsInPlaylist(playlistId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail playlist'),
        actions: [
          IconButton(
            tooltip: 'Ubah nama playlist',
            onPressed: () =>
                showPlaylistNameDialog(context, playlist: playlist),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Tambahkan lagu ke playlist',
            onPressed: () => _showAddTracks(context, playlist),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            const SizedBox(height: 12),
            Center(child: _PlaylistMosaic(songs: songs)),
            const SizedBox(height: 24),
            Text(
              playlist.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${songs.length} lagu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: SonoraColors.muted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () async {
                            await state.playCollection(songs);
                            onOpenPlayer();
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Putar semua'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Putar playlist secara acak',
                  onPressed: songs.isEmpty
                      ? null
                      : () async {
                          await state.playCollection(songs, shuffled: true);
                          onOpenPlayer();
                        },
                  icon: const Icon(Icons.shuffle_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (songs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Belum ada lagu. Tambahkan melalui tombol di kanan atas.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: songs.length,
                onReorderItem: (oldIndex, newIndex) =>
                    state.reorderPlaylistTracks(playlistId, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return MediaListTile(
                    key: ValueKey('$playlistId-${song.id}'),
                    item: song,
                    onTap: () {
                      state.playItem(song);
                      onOpenPlayer();
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Hapus ${song.title} dari playlist',
                          onPressed: () async {
                            await state.removeFromPlaylist(playlistId, song.id);
                            if (!context.mounted) return;
                            showAppMessage(
                              context,
                              'Lagu dihapus dari playlist.',
                            );
                          },
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTracks(BuildContext context, Playlist playlist) async {
    final state = SonoraScope.of(context);
    final available = state.songs
        .where((song) => !playlist.trackIds.contains(song.id))
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: available.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Semua lagu di library sudah ada di playlist ini.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final song = available[index];
                  return ListTile(
                    leading: MediaArtwork.forItem(song, dimension: 44),
                    title: Text(song.title, maxLines: 1),
                    subtitle: Text(song.artist, maxLines: 1),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await state.addToPlaylist(playlist.id, song.id);
                      if (!context.mounted) return;
                      showAppMessage(
                        context,
                        'Ditambahkan ke ${playlist.name}.',
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
