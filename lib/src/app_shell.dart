import 'package:flutter/material.dart';

import '../main.dart';
import 'artwork.dart';
import 'preview_state.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/videos_screen.dart';
import 'screens/player_screen.dart';
import 'theme.dart';
import 'widgets/shared.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.startupWarning});

  /// Pesan sekali tampil bila lapisan data gagal disiapkan.
  final String? startupWarning;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      HomeScreen(onOpenPlayer: openPlayer),
      LibraryScreen(onOpenPlayer: openPlayer),
      PlaylistsScreen(onOpenPlayer: openPlayer),
      VideosScreen(onOpenPlayer: openPlayer),
      const SettingsScreen(),
    ];
    final warning = widget.startupWarning;
    if (warning != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAppMessage(context, warning);
      });
    }
  }

  void openPlayer() {
    final state = PreviewScope.of(context);
    final item = state.selected;
    if (item == null) return;
    if (item.kind == MediaKind.video) {
      openVideoPreview(context, item);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScope(state: state, child: const PlayerScreen()),
      ),
    );
  }

  Future<void> showMediaOptions(MediaItem item) async {
    final state = PreviewScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                leading: MediaArtwork(style: item.style, dimension: 56),
                title: Text(item.title, maxLines: 2),
                subtitle: Text(item.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Pilih untuk preview'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  state.select(item);
                  openPlayer();
                },
              ),
              if (item.kind == MediaKind.audio) ...[
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
              ],
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: SonoraColors.danger,
                ),
                title: const Text(
                  'Hapus dari library',
                  style: TextStyle(color: SonoraColors.danger),
                ),
                subtitle: const Text('Preview saja • file asli tidak dihapus'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  state.hideMedia(item.id);
                  showAppMessage(
                    context,
                    'Item contoh disembunyikan. Tidak ada file asli yang dihapus.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: state.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(state.tab),
            child: screens[state.tab],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(onOpen: openPlayer),
            NavigationBar(
              selectedIndex: state.tab,
              onDestinationSelected: state.setTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.queue_music_outlined),
                  selectedIcon: Icon(Icons.queue_music_rounded),
                  label: 'Playlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library_rounded),
                  label: 'Video',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
