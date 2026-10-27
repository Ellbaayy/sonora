import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'playlists_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final search = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    if (!state.previewMode) {
      return Column(
        children: [
          const ScreenHeader(title: 'Pustaka musik'),
          Expanded(
            child: EmptyLibrary(
              kind: MediaKind.audio,
              onImport: () => showImportPreview(context, kind: MediaKind.audio),
              onPreview: state.showPreview,
            ),
          ),
        ],
      );
    }
    var songs = state.search(query);
    songs = [...songs]
      ..sort(
        (a, b) => switch (state.sort) {
          'Judul' => a.title.compareTo(b.title),
          'Artis' => a.artist.compareTo(b.artist),
          'Durasi' => a.duration.compareTo(b.duration),
          _ => b.id.compareTo(a.id),
        },
      );
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        const SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Pustaka musik',
            subtitle: 'Semua yang kamu simpan, dalam satu tempat.',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                LocalSearchField(
                  controller: search,
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${songs.length} lagu contoh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Urutkan lagu',
                      initialValue: state.sort,
                      onSelected: state.setSort,
                      itemBuilder: (context) =>
                          ['Terbaru ditambahkan', 'Judul', 'Artis', 'Durasi']
                              .map(
                                (value) => PopupMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sort_rounded,
                              size: 20,
                              color: SonoraColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.sort,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: SonoraColors.primary),
                            ),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: SonoraColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabHeader(
            TabBar(
              controller: tabs,
              dividerColor: Colors.transparent,
              indicatorColor: SonoraColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: SonoraColors.text,
              unselectedLabelColor: SonoraColors.muted,
              labelStyle: Theme.of(context).textTheme.labelLarge,
              tabs: const [
                Tab(text: 'Lagu'),
                Tab(text: 'Artis'),
                Tab(text: 'Album'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: tabs,
        children: [
          _SongList(
            songs: songs,
            query: query,
            onOpenPlayer: widget.onOpenPlayer,
          ),
          _GroupedCollection(
            groupByArtist: true,
            onOpenPlayer: widget.onOpenPlayer,
          ),
          _GroupedCollection(
            groupByArtist: false,
            onOpenPlayer: widget.onOpenPlayer,
          ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: SonoraColors.muted),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  const _TabHeader(this.tabBar);
  final TabBar tabBar;
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: SonoraColors.background,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: tabBar,
    ),
  );
  @override
  bool shouldRebuild(covariant _TabHeader oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

class _SongList extends StatelessWidget {
  const _SongList({
    required this.songs,
    required this.query,
    required this.onOpenPlayer,
  });
  final List<MediaItem> songs;
  final String query;
  final VoidCallback onOpenPlayer;
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Tidak ada lagu yang cocok dengan “$query”.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: SonoraColors.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: songs.length + 1,
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: PreviewNotice(compact: true),
          );
        }
        final song = songs[index];
        return MediaListTile(
          key: ValueKey(song.id),
          item: song,
          onTap: () {
            state.select(song);
            onOpenPlayer();
          },
          onMenu: () => _showOptions(context, song),
        );
      },
    );
  }
}

void _showOptions(BuildContext context, MediaItem item) {
  final state = PreviewScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: MediaArtwork(style: item.style, dimension: 56),
              title: Text(item.title),
              subtitle: Text(item.artist),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Tambahkan ke antrean'),
              onTap: () {
                Navigator.pop(sheetContext);
                state.enqueue(item.id);
                showAppMessage(
                  context,
                  'Ditambahkan ke antrean preview. Belum tersimpan setelah restart.',
                );
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
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: SonoraColors.danger,
              ),
              title: const Text(
                'Hapus item contoh',
                style: TextStyle(color: SonoraColors.danger),
              ),
              subtitle: const Text('Tidak ada file perangkat yang dihapus'),
              onTap: () {
                Navigator.pop(sheetContext);
                state.hideMedia(item.id);
                showAppMessage(
                  context,
                  'Item contoh disembunyikan dari library.',
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _GroupedCollection extends StatelessWidget {
  const _GroupedCollection({
    required this.groupByArtist,
    required this.onOpenPlayer,
  });
  final bool groupByArtist;
  final VoidCallback onOpenPlayer;
  @override
  Widget build(BuildContext context) {
    final songs = PreviewScope.of(context).songs;
    final names = <String>{
      for (final song in songs) groupByArtist ? song.artist : song.album,
    }.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        final group = songs
            .where((song) => (groupByArtist ? song.artist : song.album) == name)
            .toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: SonoraColors.primary.withValues(alpha: .15),
              child: Icon(
                groupByArtist
                    ? Icons.person_outline_rounded
                    : Icons.album_outlined,
                color: SonoraColors.primary,
              ),
            ),
            title: Text(name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('${group.length} lagu'),
            children: group
                .map(
                  (song) => MediaListTile(
                    item: song,
                    onTap: () {
                      PreviewScope.of(context).select(song);
                      onOpenPlayer();
                    },
                    trailing: const SizedBox(width: 12),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
