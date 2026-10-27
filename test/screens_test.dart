import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/main.dart';
import 'package:sonora/src/app_shell.dart';
import 'package:sonora/src/preview_state.dart';
import 'package:sonora/src/screens/home_screen.dart';
import 'package:sonora/src/screens/player_screen.dart';
import 'package:sonora/src/screens/videos_screen.dart';
import 'package:sonora/src/theme.dart';

Future<PreviewState> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final state = PreviewState();
  await tester.pumpWidget(
    PreviewScope(
      state: state,
      child: MaterialApp(
        theme: sonoraTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });
  return state;
}

void main() {
  testWidgets('Now Playing menampilkan kontrol dan antrean preview', (
    tester,
  ) async {
    final state = await pumpScreen(tester, const PlayerScreen());
    expect(find.text('Midnight in Jakarta'), findsOneWidget);
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('Pratinjau antarmuka'), findsOneWidget);
    await tester.tap(find.byTooltip('Buka antrean'));
    await tester.pumpAndSettle();
    expect(find.text('Antrean'), findsOneWidget);
    expect(find.text('Blue Hours'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus Blue Hours dari antrean'));
    await tester.pumpAndSettle();
    expect(state.queue.map((item) => item.id), ['song-3', 'song-4']);
    expect(tester.takeException(), isNull);

    final firstItemActions = find
        .ancestor(
          of: find.byKey(const ValueKey('0-song-3')),
          matching: find.byType(Semantics),
        )
        .evaluate()
        .map((element) => element.widget as Semantics)
        .firstWhere(
          (widget) => widget.properties.customSemanticsActions != null,
        )
        .properties
        .customSemanticsActions!;
    expect(firstItemActions.length, 2);
    firstItemActions.values.last();
    await tester.pumpAndSettle();
    expect(state.queue.map((item) => item.id), ['song-4', 'song-3']);
  });

  testWidgets('Antrean mendukung drag dan konfirmasi pengosongan', (
    tester,
  ) async {
    final state = await pumpScreen(tester, const QueueScreen());
    await tester.tap(find.byTooltip('Hapus Blue Hours dari antrean'));
    await tester.pumpAndSettle();
    expect(state.queue.map((item) => item.id), ['song-3', 'song-4']);

    final nextItem = find.byKey(const ValueKey('1-song-4'));
    final dragHandle = find.descendant(
      of: find.byKey(const ValueKey('0-song-3')),
      matching: find.byIcon(Icons.drag_handle_rounded),
    );
    final offset =
        tester.getBottomLeft(nextItem) +
        const Offset(0, 24) -
        tester.getCenter(dragHandle);
    await tester.timedDrag(
      dragHandle,
      offset,
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(state.queue.map((item) => item.id), ['song-4', 'song-3']);

    await tester.tap(find.byTooltip('Hapus seluruh antrean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(state.queue, isNotEmpty);
    await tester.tap(find.byTooltip('Hapus seluruh antrean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kosongkan'));
    await tester.pumpAndSettle();
    expect(find.text('Antrean masih kosong'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Now Playing tidak overflow pada lebar 360 dan text scale 1.3', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const PlayerScreen(),
      size: const Size(360, 800),
      textScale: 1.3,
    );
    await tester.scrollUntilVisible(
      find.text('Kontrol seek dan volume hanya mengubah nilai preview.'),
      80,
    );
    await tester.pumpAndSettle();
    expect(find.text('Playlist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kelima navigasi dapat dibuka pada layar kecil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(const SonoraApp());
    await tester.pumpAndSettle();
    for (final (label, expected) in [
      ('Library', 'Pustaka musik'),
      ('Playlist', 'Suasana yang berbeda, satu koleksi.'),
      ('Video', 'Ruang video'),
      ('Settings', 'Pengaturan'),
      ('Home', 'SONORA'),
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(expected), findsWidgets, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Playlist baru menolak nama kosong lalu menerima nama valid', (
    tester,
  ) async {
    await tester.pumpWidget(const SonoraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playlist').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buat playlist baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama playlist tidak boleh kosong.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Teman perjalanan');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Teman perjalanan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Teman perjalanan'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teman perjalanan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada lagu. Tambahkan melalui menu lagu di Library.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Ubah nama playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Perjalanan pulang');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Perjalanan pulang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home tetap terbuka setelah jumlah playlist berkurang', (
    tester,
  ) async {
    await tester.pumpWidget(const SonoraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playlist').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opsi playlist Easy Sunday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Late Night'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Late Night'), findsOneWidget);
    expect(find.text('Easy Sunday'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Playlist').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opsi playlist Late Night'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Belum ada playlist'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada playlist'), findsOneWidget);
    expect(find.text('Buat playlist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home menampilkan keadaan kosong setelah semua lagu disembunyikan',
    (tester) async {
      final state = PreviewState();
      addTearDown(state.dispose);
      for (final song in sampleSongs) {
        state.hideMedia(song.id);
      }
      await tester.pumpWidget(
        PreviewScope(
          state: state,
          child: MaterialApp(
            theme: sonoraTheme(),
            home: Scaffold(body: HomeScreen(onOpenPlayer: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Impor musik'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Lihat tampilan contoh'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat tampilan contoh'));
      await tester.pumpAndSettle();
      expect(state.previewMode, isTrue);
      expect(find.text('Pratinjau antarmuka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home tidak memaksa tiga kartu saat hanya dua lagu tersisa', (
    tester,
  ) async {
    final state = PreviewState();
    addTearDown(state.dispose);
    for (final song in sampleSongs.take(4)) {
      state.hideMedia(song.id);
    }
    await tester.pumpWidget(
      PreviewScope(
        state: state,
        child: MaterialApp(
          theme: sonoraTheme(),
          home: Scaffold(body: HomeScreen(onOpenPlayer: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Analog Sunday'), findsOneWidget);
    expect(find.text('The Way Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Video preview menjelaskan batas playback dan mengubah seek UI', (
    tester,
  ) async {
    final state = await pumpScreen(
      tester,
      VideoPreviewScreen(video: sampleVideos.first),
    );
    await tester.tap(find.byTooltip('Pratinjau kontrol video'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Pemutaran MP4 belum terhubung'),
      findsOneWidget,
    );
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    expect(state.position, greaterThan(0));
    expect(state.isPlaying, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home tidak overflow pada lebar 360 dan text scale 1.3', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(body: HomeScreen(onOpenPlayer: () {})),
      size: const Size(360, 780),
      textScale: 1.3,
    );
    final scrollable = find.byType(Scrollable).first;
    expect(find.text('Baru diputar'), findsOneWidget);
    for (var step = 0; step < 6; step++) {
      await tester.drag(scrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Reduce Motion membuat transisi route instan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sonoraTheme(reduceMotion: true),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Tujuan')),
                  ),
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.text('Tujuan')))!;
    expect(route.animation!.isCompleted, isTrue);
  });

  testWidgets('aplikasi meneruskan Reduce Motion ke transisi tema', (
    tester,
  ) async {
    await tester.pumpWidget(const SonoraApp());
    final state = PreviewScope.of(tester.element(find.byType(AppShell)));
    state.setReduceMotion(true);
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
}
