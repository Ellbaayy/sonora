import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/app_shell.dart';
import 'package:sonora/src/screens/home_screen.dart';
import 'package:sonora/src/screens/player_screen.dart';
import 'package:sonora/src/screens/playlists_screen.dart';
import 'package:sonora/src/widgets/dynamic_island_nav.dart';

import 'helpers.dart';

void main() {
  testWidgets('Home menampilkan lagu dari library, bukan data contoh', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Midnight in Jakarta', artist: 'Nara'),
        audioDraft('b.mp3', title: 'Blue Hours', artist: 'Nara'),
      ],
    );
    await pumpApp(tester, harness);

    expect(find.text('Midnight in Jakarta'), findsWidgets);
    expect(find.text('Baru ditambahkan'), findsOneWidget);
    expect(find.text('Pratinjau antarmuka'), findsNothing);
    expect(find.byType(IslandMiniPlayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library kosong menampilkan ajakan impor', (tester) async {
    final harness = await createHarness();
    await pumpApp(tester, harness);

    expect(find.text('Impor musik'), findsOneWidget);
    expect(find.text('Koleksimu. Tetap milikmu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mini player dynamic island muncul setelah lagu diputar', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Midnight in Jakarta')],
    );
    await pumpApp(tester, harness);
    await harness.state.playItem(harness.state.songs.single);
    await tester.pumpAndSettle();

    expect(find.byType(IslandMiniPlayer), findsOneWidget);
    expect(harness.state.isPlaying, isTrue);

    await tester.tap(find.byTooltip('Jeda'));
    await tester.pumpAndSettle();
    expect(harness.state.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Now Playing memutar, menjeda, dan menggeser posisi', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Midnight in Jakarta')],
    );
    await harness.state.playItem(harness.state.songs.single);
    await harness.state.togglePlay();
    await pumpScreen(tester, harness, const PlayerScreen());

    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('Midnight in Jakarta'), findsOneWidget);

    await tester.tap(find.byTooltip('Putar'));
    await tester.pumpAndSettle();
    expect(harness.state.isPlaying, isTrue);

    await tester.tap(find.byType(Slider).first);
    await tester.pumpAndSettle();
    expect(harness.state.position, greaterThan(Duration.zero));

    await tester.tap(find.byTooltip('Jeda'));
    await tester.pumpAndSettle();
    expect(harness.state.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('antrean dapat menghapus item dan dikosongkan', (tester) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Alpha'),
        audioDraft('b.mp3', title: 'Beta'),
        audioDraft('c.mp3', title: 'Gamma'),
      ],
    );
    final songs = harness.state.songs;
    await harness.state.enqueue(songs[0].id);
    await harness.state.enqueue(songs[1].id);
    expect(harness.state.queueIds, [songs[0].id, songs[1].id]);
    await pumpScreen(tester, harness, const QueueScreen());

    expect(find.text(songs[0].title), findsWidgets);
    await tester.tap(find.byTooltip('Hapus ${songs[0].title} dari antrean'));
    await tester.pumpAndSettle();
    expect(harness.state.queueIds, [songs[1].id]);

    await tester.tap(find.byTooltip('Hapus seluruh antrean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kosongkan'));
    await tester.pumpAndSettle();
    expect(find.text('Antrean masih kosong'), findsOneWidget);
    expect(harness.state.queueIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlist baru menolak nama kosong lalu menyimpan nama valid', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Alpha')],
    );
    await pumpApp(tester, harness);
    await tester.tap(find.byKey(const ValueKey('nav-Playlist')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buat playlist baru').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama playlist tidak boleh kosong.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Teman perjalanan');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Teman perjalanan'), findsWidgets);
    expect(harness.state.playlists.single.name, 'Teman perjalanan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail playlist memutar semua lagu ke antrean', (tester) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Alpha'),
        audioDraft('b.mp3', title: 'Beta'),
      ],
    );
    await harness.state.createPlaylist('Malam');
    final playlist = harness.state.playlists.single;
    for (final song in harness.state.songs) {
      await harness.state.addToPlaylist(playlist.id, song.id);
    }
    await pumpScreen(
      tester,
      harness,
      PlaylistDetailScreen(playlistId: playlist.id, onOpenPlayer: () {}),
    );

    expect(find.text('Malam'), findsOneWidget);
    await tester.tap(find.text('Putar semua'));
    await tester.pumpAndSettle();

    expect(harness.state.queueIds, hasLength(2));
    expect(harness.state.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home dan Now Playing tidak overflow pada 360 dan skala 1.3', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Midnight in Jakarta', artist: 'Nara'),
        audioDraft('b.mp3', title: 'Blue Hours', artist: 'Nara'),
        audioDraft('c.mp3', title: 'Slow Orbit', artist: 'Aster'),
      ],
    );
    await pumpScreen(
      tester,
      harness,
      const HomeScreen(onOpenPlayer: _noop),
      size: const Size(360, 780),
      textScale: 1.3,
    );
    final scrollable = find.byType(Scrollable).first;
    for (var step = 0; step < 6; step++) {
      await tester.drag(scrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Now Playing tidak overflow pada lebar 360 dan skala 1.3', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Midnight in Jakarta')],
    );
    await harness.state.playItem(harness.state.songs.single);
    await pumpScreen(
      tester,
      harness,
      const PlayerScreen(),
      size: const Size(360, 800),
      textScale: 1.3,
    );
    await tester.scrollUntilVisible(
      find.text('Playlist'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Playlist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kelima tujuan navigasi dapat dibuka', (tester) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Alpha'),
        videoDraft('b.mp4', title: 'Klip'),
      ],
    );
    await pumpApp(tester, harness, size: const Size(360, 800));

    for (final (label, expected) in [
      ('Library', 'Pustaka musik'),
      ('Playlist', 'Suasana yang berbeda, satu koleksi.'),
      ('Video', 'Ruang video'),
      ('Settings', 'Pengaturan'),
      ('Home', 'SONORA'),
    ]) {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsWidgets, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduce Motion diteruskan ke transisi tema', (tester) async {
    final harness = await createHarness();
    await pumpApp(tester, harness);
    await harness.state.setReduceMotion(true);
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(AppShell)));
    expect(
      theme
          .pageTransitionsTheme
          .builders[TargetPlatform.android]!
          .transitionDuration,
      Duration.zero,
    );
  });

  testWidgets('pencarian Home menyaring library', (tester) async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Midnight in Jakarta'),
        audioDraft('b.mp3', title: 'Blue Hours'),
      ],
    );
    await pumpScreen(tester, harness, const HomeScreen(onOpenPlayer: _noop));

    await tester.enterText(find.byType(TextField), 'blue');
    await tester.pumpAndSettle();
    expect(find.text('Hasil pencarian'), findsOneWidget);
    expect(find.text('Blue Hours'), findsOneWidget);
    expect(find.text('Midnight in Jakarta'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
