import 'package:flutter/material.dart';

import '../app_state.dart';
import '../media/media_item.dart';
import '../theme.dart';
import '../widgets/shared.dart';

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
    final state = SonoraScope.of(context);
    if (state.songs.isEmpty) {
      return Column(
        children: [
          ScreenHeader(
            title: 'Pustaka musik',
            action: IconButton(
              tooltip: 'Impor musik',
              onPressed: () => runMediaImport(context, MediaKind.audio),
              icon: const Icon(Icons.add_rounded),
            ),
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
    var songs = state.search(query);
    songs = [...songs]
      ..sort(
        (a, b) => switch (state.sort) {
          'Judul' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          'Artis' => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
          'Durasi' => a.duration.compareTo(b.duration),
          _ => (b.lastPlayedAt ?? 0).compareTo(a.lastPlayedAt ?? 0),
        },
      );
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: ScreenHeader(
            title: 'Pustaka musik',
            subtitle: 'Semua yang kamu simpan, dalam satu tempat.',
            action: IconButton(
              tooltip: 'Impor musik',
              onPressed: () => runMediaImport(context, MediaKind.audio),
              icon: const Icon(Icons.add_rounded),
            ),
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
                        '${songs.length} lagu',
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
    final state = SonoraScope.of(context);
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
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return MediaListTile(
          key: ValueKey(song.id),
          item: song,
          onTap: () {
            state.playItem(song);
            onOpenPlayer();
          },
          onMenu: () => showMediaOptions(context, song),
        );
      },
    );
  }
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
    final state = SonoraScope.of(context);
    final songs = state.songs;
    final names = <String>{
      for (final song in songs) groupByArtist ? song.artist : song.album,
    }.toList()..sort();
    if (names.isEmpty) {
      return const Center(child: Text('Belum ada lagu di library.'));
    }
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
                      state.playItem(song);
                      onOpenPlayer();
                    },
                    onMenu: () => showMediaOptions(context, song),
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
