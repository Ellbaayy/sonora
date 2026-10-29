import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonora/main.dart';
import 'package:sonora/src/app_state.dart';
import 'package:sonora/src/data/backend.dart';
import 'package:sonora/src/data/database.dart';
import 'package:sonora/src/data/models.dart';
import 'package:sonora/src/media/media_item.dart';
import 'package:sonora/src/media/media_library.dart';
import 'package:sonora/src/playback/audio_engine.dart';
import 'package:sonora/src/theme.dart';

MediaDraft audioDraft(
  String fileName, {
  String? title,
  String? artist,
  String? album,
  int durationMs = 180000,
  int sizeBytes = 1024,
}) => MediaDraft(
  uri: '/media/$fileName',
  fileName: fileName,
  mediaType: MediaType.audio,
  title: title,
  artist: artist,
  album: album,
  durationMs: durationMs,
  fileSizeBytes: sizeBytes,
);

MediaDraft videoDraft(
  String fileName, {
  String? title,
  int durationMs = 60000,
  int sizeBytes = 2048,
}) => MediaDraft(
  uri: '/media/$fileName',
  fileName: fileName,
  mediaType: MediaType.video,
  title: title,
  durationMs: durationMs,
  fileSizeBytes: sizeBytes,
);

/// Pemilih berkas tiruan untuk pengujian impor.
class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker([this.files = const []]);

  List<PickedMedia> files;
  MediaType? lastType;

  @override
  Future<List<PickedMedia>> pick(MediaType type) async {
    lastType = type;
    return files;
  }
}

/// Membuat berkas sumber nyata di disk agar alur salin impor teruji.
Future<PickedMedia> tempPickedFile(
  Directory root,
  String fileName, {
  int bytes = 512,
}) async {
  final file = File(p.join(root.path, 'sumber-$fileName'));
  await file.writeAsBytes(Uint8List(bytes)..fillRange(0, bytes, 7));
  return PickedMedia(fileName: fileName, sizeBytes: bytes, path: file.path);
}

/// Lingkungan pengujian: database di memori, penyimpanan sementara, dan mesin
/// audio tiruan.
class Harness {
  Harness({
    required this.backend,
    required this.state,
    required this.engine,
    required this.storage,
    required this.root,
    required this.picker,
  });

  final SonoraBackend backend;
  final SonoraState state;
  final FakeAudioEngine engine;
  final MediaStorage storage;
  final Directory root;
  final FakeMediaPicker picker;

  List<MediaItem> get songs => state.songs;

  Future<void> close() async {
    state.dispose();
    await backend.close();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}

Future<Harness> createHarness({
  List<MediaDraft> seeds = const [],
  FakeMediaPicker? picker,
  bool withLibrary = true,
  bool autoAdvance = false,
}) async {
  final root = Directory.systemTemp.createTempSync('sonora_test_');
  final backend = SonoraBackend(SonoraDatabase(NativeDatabase.memory()));
  if (seeds.isNotEmpty) {
    await backend.media.importDrafts(seeds);
  }
  final storage = await MediaStorage.at(Directory(p.join(root.path, 'app')));
  final engine = FakeAudioEngine(autoAdvance: autoAdvance);
  final mediaPicker = picker ?? FakeMediaPicker();
  final state = SonoraState(
    engine,
    backend: backend,
    library: withLibrary
        ? MediaLibraryService(
            backend: backend,
            picker: mediaPicker,
            storage: storage,
          )
        : null,
    saveDebounce: Duration.zero,
  );
  await state.init();
  return Harness(
    backend: backend,
    state: state,
    engine: engine,
    storage: storage,
    root: root,
    picker: mediaPicker,
  );
}

/// Menyiapkan aplikasi lengkap dengan state tertentu.
Future<void> pumpApp(
  WidgetTester tester,
  Harness harness, {
  Size size = const Size(412, 915),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
    await harness.close();
  });
  await tester.pumpWidget(SonoraApp(state: harness.state));
  await tester.pumpAndSettle();
}

/// Menyiapkan satu layar dengan scope state yang sama.
Future<void> pumpScreen(
  WidgetTester tester,
  Harness harness,
  Widget child, {
  Size size = const Size(412, 915),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
    await harness.close();
  });
  await tester.pumpWidget(
    SonoraScope(
      state: harness.state,
      child: MaterialApp(
        theme: sonoraTheme(
          cyanAccent: harness.state.cyanAccent,
          reduceMotion: harness.state.reduceMotion,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Menunggu nilai preferensi tersimpan (penulisan berjalan tanpa ditunggu).
Future<void> waitForSetting(
  SonoraBackend backend,
  String key,
  String expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (await backend.settings.read(key) == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Pengaturan $key tidak tersimpan sebagai $expected.');
}
