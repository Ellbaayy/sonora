import 'package:flutter/material.dart';

import 'app_state.dart';
import 'media/media_item.dart';
import 'playback/notification_permission.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/player_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/videos_screen.dart';
import 'widgets/dynamic_island_nav.dart';
import 'widgets/shared.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.startupWarning});

  /// Pesan sekali tampil bila lapisan data gagal disiapkan.
  final String? startupWarning;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = [
    IslandDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    IslandDestination(
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music_rounded,
      label: 'Library',
    ),
    IslandDestination(
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music_rounded,
      label: 'Playlist',
    ),
    IslandDestination(
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library_rounded,
      label: 'Video',
    ),
    IslandDestination(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
      label: 'Settings',
    ),
  ];

  SonoraState? _state;
  String? _handledNotice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = SonoraScope.of(context);
    if (!identical(state, _state)) {
      _state?.removeListener(_handleStateChange);
      _state = state..addListener(_handleStateChange);
    }
    final warning = widget.startupWarning;
    if (warning != null && _handledNotice == null) {
      _handledNotice = warning;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAppMessage(context, warning);
      });
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_handleStateChange);
    super.dispose();
  }

  /// Menampilkan pesan dari state (berkas hilang, gagal menyimpan) sekali saja.
  void _handleStateChange() {
    final state = _state;
    if (state == null || !mounted) return;
    final notice = state.notice;
    if (notice == null || notice == _handledNotice) return;
    _handledNotice = notice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = state.takeNotice();
      if (pending == null) return;
      _handledNotice = null;
      showAppMessage(context, pending);
    });
  }

  void openPlayer() {
    final state = SonoraScope.of(context);
    final item = state.selected;
    if (item == null) return;
    if (item.kind == MediaKind.video) {
      openVideoPlayer(context, item);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SonoraScope(state: state, child: const PlayerScreen()),
      ),
    );
  }

  Future<void> _playSelected() async {
    final state = SonoraScope.of(context);
    await ensureNotificationPermission();
    await state.togglePlay();
  }

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final item = state.selected;
    final showMiniPlayer = item != null && item.kind == MediaKind.audio;
    final animationDuration = state.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    final screens = [
      HomeScreen(onOpenPlayer: openPlayer),
      LibraryScreen(onOpenPlayer: openPlayer),
      PlaylistsScreen(onOpenPlayer: openPlayer),
      VideosScreen(onOpenPlayer: openPlayer),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: animationDuration,
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
      bottomNavigationBar: keyboardVisible
          ? null
          : SafeArea(
              top: false,
              child: AnimatedSize(
                duration: animationDuration,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showMiniPlayer)
                      ValueListenableBuilder<Duration>(
                        valueListenable: state.positionNotifier,
                        builder: (context, position, _) => IslandMiniPlayer(
                          item: item,
                          playing: state.isPlaying,
                          position: position,
                          duration: state.duration,
                          reduceMotion: state.reduceMotion,
                          onOpen: openPlayer,
                          onTogglePlay: _playSelected,
                        ),
                      ),
                    DynamicIslandNavigation(
                      destinations: _destinations,
                      selectedIndex: state.tab,
                      onSelected: state.setTab,
                      reduceMotion: state.reduceMotion,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
