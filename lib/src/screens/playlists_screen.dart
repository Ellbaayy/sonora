import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;
  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
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
        if (state.previewMode) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: PreviewNotice(compact: true),
          ),
          const SizedBox(height: 20),
          ...state.playlists.map((playlist) {
            final songs = state.songsInPlaylist(playlist.id);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PreviewScope(
                        state: state,
                        child: PlaylistDetailScreen(
                          playlistId: playlist.id,
                          onOpenPlayer: widget.onOpenPlayer,
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
        ] else ...[
          SizedBox(
            height: 300,
            child: EmptyLibrary(
              kind: MediaKind.audio,
              onImport: () => showImportPreview(context, kind: MediaKind.audio),
              onPreview: state.showPreview,
            ),
          ),
        ],
      ],
    );
  }

  void _playlistOptions(BuildContext context, Playlist playlist) {
    showModalBottomSheet<void>(
      context: context,
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
    final state = PreviewScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus playlist?'),
        content: Text(
          '“${playlist.name}” akan dihapus dari preview ini. File media tidak akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SonoraColors.danger),
            onPressed: () {
              Navigator.pop(dialogContext);
              state.deletePlaylist(playlist.id);
              showAppMessage(
                context,
                'Playlist dihapus dari preview. Belum tersimpan setelah restart.',
              );
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
          (index) => MediaArtwork(
            style: songs[index % songs.length].style,
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
  final state = PreviewScope.of(context);
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
  final String? Function(String name) onSave;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController controller;
  String? error;

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

  void save() {
    final result = widget.onSave(controller.text);
    if (result != null) {
      setState(() => error = result);
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
            maxLength: 50,
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
            'Perubahan hanya tersimpan selama preview ini terbuka.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: save, child: const Text('Simpan')),
      ],
    );
  }
}

Future<void> showAddToPlaylist(BuildContext context, MediaItem item) async {
  final state = PreviewScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Tambahkan “${item.title}” ke',
                style: Theme.of(context).textTheme.titleLarge,
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
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (exists) {
                    showAppMessage(
                      context,
                      'Lagu sudah ada di playlist tersebut.',
                    );
                  } else {
                    state.addToPlaylist(playlist.id, item.id);
                    showAppMessage(
                      context,
                      'Ditambahkan ke ${playlist.name} pada preview ini.',
                    );
                  }
                },
              );
            }),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Buat playlist baru'),
              onTap: () {
                Navigator.pop(sheetContext);
                showPlaylistNameDialog(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
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
    final state = PreviewScope.of(context);
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
              '${songs.length} lagu • Preview playlist',
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
                        : () {
                            state.select(songs.first);
                            showAppMessage(
                              context,
                              'Lagu dipilih untuk preview. Playback asli belum tersedia.',
                            );
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Putar semua'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Aktifkan acak untuk preview',
                  onPressed: () {
                    state.toggleShuffle();
                    showAppMessage(
                      context,
                      state.shuffle
                          ? 'Acak diaktifkan pada preview.'
                          : 'Acak dimatikan.',
                    );
                  },
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: state.shuffle
                        ? SonoraColors.primary
                        : SonoraColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const PreviewNotice(compact: true),
            const SizedBox(height: 12),
            if (songs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Belum ada lagu. Tambahkan melalui menu lagu di Library.',
                  ),
                ),
              )
            else
              ...songs.map(
                (song) => MediaListTile(
                  item: song,
                  onTap: () {
                    state.select(song);
                    onOpenPlayer();
                  },
                  onMenu: () {
                    state.removeFromPlaylist(playlistId, song.id);
                    showAppMessage(
                      context,
                      'Lagu dihapus dari playlist preview.',
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
