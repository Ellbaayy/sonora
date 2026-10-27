import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenPlayer});
  final VoidCallback onOpenPlayer;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();
  String query = '';
  bool searching = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    final results = state.search(query);
    final recentSongs = state.songs.take(3).toList();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ((screenWidth - 60) / 2).clamp(128.0, 190.0);
    final textScaler = MediaQuery.textScalerOf(context);
    final textTheme = Theme.of(context).textTheme;
    double lineHeight(TextStyle? style) =>
        textScaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.2);
    // Tinggi dihitung dari skala teks agar kartu tidak terpotong pada
    // pembesaran font 1.3x (DESIGN bagian 4 dan 8).
    final recentCardHeight =
        cardWidth +
        12 +
        lineHeight(textTheme.titleMedium) +
        4 +
        lineHeight(textTheme.bodySmall) +
        2;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const Expanded(child: BrandMark()),
                  IconButton(
                    tooltip: 'Buka pengaturan',
                    onPressed: () => state.setTab(4),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Dengarkan yang\nkamu simpan.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Musik lokal. Ruangmu sendiri.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: SonoraColors.muted),
              ),
              const SizedBox(height: 24),
              LocalSearchField(
                controller: search,
                onChanged: (value) => setState(() {
                  query = value;
                  searching = value.trim().isNotEmpty;
                }),
              ),
              const SizedBox(height: 16),
              if (state.previewMode && state.songs.isNotEmpty)
                const PreviewNotice()
              else ...[
                const SizedBox(height: 32),
                SizedBox(
                  height: 420,
                  child: EmptyLibrary(
                    kind: MediaKind.audio,
                    onImport: () =>
                        showImportPreview(context, kind: MediaKind.audio),
                    onPreview: state.showPreview,
                  ),
                ),
              ],
              if (state.previewMode && searching && state.songs.isNotEmpty) ...[
                const SizedBox(height: 28),
                SectionHeading(
                  'Hasil pencarian',
                  action: 'Tutup',
                  onAction: () {
                    search.clear();
                    setState(() {
                      searching = false;
                      query = '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: SonoraColors.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil untuk “$query”',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba judul, artis, atau album yang lain.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: SonoraColors.muted),
                        ),
                      ],
                    ),
                  )
                else
                  ...results.map(
                    (item) => MediaListTile(
                      key: ValueKey(item.id),
                      item: item,
                      onTap: () {
                        state.select(item);
                        widget.onOpenPlayer();
                      },
                      onMenu: () => state.select(item),
                    ),
                  ),
              ] else if (state.previewMode && state.songs.isNotEmpty) ...[
                const SizedBox(height: 32),
                SectionHeading(
                  'Baru diputar',
                  action: 'Lihat semua',
                  onAction: () => state.setTab(1),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: recentCardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: recentSongs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final item = recentSongs[index];
                      return HorizontalMediaCard(
                        item: item,
                        width: cardWidth,
                        onTap: () {
                          state.select(item);
                          widget.onOpenPlayer();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SectionHeading(
                  'Baru ditambahkan',
                  action: 'Impor',
                  onAction: () =>
                      showImportPreview(context, kind: MediaKind.audio),
                ),
                const SizedBox(height: 8),
                ...state.songs
                    .skip(3)
                    .take(3)
                    .map(
                      (item) => MediaListTile(
                        item: item,
                        onTap: () {
                          state.select(item);
                          widget.onOpenPlayer();
                        },
                        onMenu: () {
                          state.select(item);
                          showAppMessage(
                            context,
                            'Item dipilih. Buka Library untuk opsi media.',
                          );
                        },
                      ),
                    ),
                const SizedBox(height: 28),
                SectionHeading(
                  'Playlist kamu',
                  action: 'Lihat semua',
                  onAction: () => state.setTab(2),
                ),
                const SizedBox(height: 16),
                if (state.playlists.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.queue_music_outlined,
                            color: SonoraColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada playlist',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => state.setTab(2),
                            child: const Text('Buat playlist'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      for (final (index, playlist)
                          in state.playlists.take(2).indexed) ...[
                        if (index > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _PlaylistPreviewCard(
                            playlist: playlist,
                            icon: index == 0
                                ? Icons.nightlight_outlined
                                : Icons.wb_sunny_outlined,
                            onTap: () => state.setTab(2),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _PlaylistPreviewCard extends StatelessWidget {
  const _PlaylistPreviewCard({
    required this.playlist,
    required this.icon,
    required this.onTap,
  });
  final Playlist playlist;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final count = PreviewScope.of(context).songsInPlaylist(playlist.id).length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SonoraColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SonoraColors.primary, size: 22),
              ),
              const SizedBox(height: 20),
              Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('$count lagu', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
