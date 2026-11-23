import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonora/src/data/backend.dart';
import 'package:sonora/src/data/database.dart';
import 'package:sonora/src/data/models.dart';
import 'package:sonora/src/media/media_library.dart';

import 'helpers.dart';

MediaDraft _draftFor(String uri, String fileName, {int sizeBytes = 512}) =>
    MediaDraft(
      uri: uri,
      fileName: fileName,
      mediaType: MediaType.audio,
      durationMs: 1000,
      fileSizeBytes: sizeBytes,
    );

void main() {
  late Directory root;
  late MediaStorage storage;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('sonora_storage_');
    storage = await MediaStorage.at(Directory(p.join(root.path, 'app')));
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('MediaStorage.copyIn', () {
    test('menolak salinan kosong dari sumber yang ukurannya nol', () async {
      final source = File(p.join(root.path, 'kosong.mp3'))
        ..writeAsBytesSync([]);
      final picked = PickedMedia(
        fileName: 'kosong.mp3',
        sizeBytes: 0,
        path: source.path,
      );

      await expectLater(
        () => storage.copyIn(picked),
        throwsA(isA<MediaImportException>()),
      );
      expect(
        storage.mediaDir.listSync(),
        isEmpty,
        reason: 'salinan kosong tidak boleh ditinggalkan di penyimpanan',
      );
    });

    test('menolak salinan yang terpotong dari ukuran sumber', () async {
      final picked = await tempPickedFile(root, 'terpotong.mp3', bytes: 100);
      final salahUkuran = PickedMedia(
        fileName: picked.fileName,
        sizeBytes: 4096,
        path: picked.path,
        openStream: picked.openStream,
      );

      await expectLater(
        () => storage.copyIn(salahUkuran),
        throwsA(isA<MediaImportException>()),
      );
      expect(storage.mediaDir.listSync(), isEmpty);
    });

    test('menerima salinan utuh dan mengembalikan path di mediaDir', () async {
      final picked = await tempPickedFile(root, 'utuh.mp3', bytes: 512);

      final path = await storage.copyIn(picked);

      expect(p.dirname(path), storage.mediaDir.path);
      expect(p.extension(path), '.mp3');
      expect(File(path).lengthSync(), 512);
    });
  });

  group('MediaLibraryService.verifyAvailability', () {
    late SonoraBackend backend;
    late MediaLibraryService library;

    setUp(() {
      backend = SonoraBackend(SonoraDatabase(NativeDatabase.memory()));
      library = MediaLibraryService(
        backend: backend,
        picker: FakeMediaPicker(),
        storage: storage,
      );
    });

    test('menandai salinan aplikasi yang berkasnya hilang', () async {
      final hilang = p.join(storage.mediaDir.path, 'hilang.mp3');
      await backend.media.importDrafts([_draftFor(hilang, 'hilang.mp3')]);

      final changed = await library.verifyAvailability();

      expect(changed, 1);
      final rows = await backend.media.all();
      expect(rows.single.availability, 'unavailable');
    });

    test('mempertahankan salinan aplikasi yang berkasnya ada', () async {
      final ada = p.join(storage.mediaDir.path, 'ada.mp3');
      File(ada).writeAsBytesSync(List<int>.filled(512, 1));
      await backend.media.importDrafts([_draftFor(ada, 'ada.mp3')]);

      final changed = await library.verifyAvailability();

      expect(changed, 0);
      final rows = await backend.media.all();
      expect(rows.single.availability, 'available');
    });

    test('tidak menyentuh URI di luar penyimpanan aplikasi', () async {
      await backend.media.importDrafts([
        _draftFor('content://media/external/audio/9', 'luar.mp3'),
      ]);

      final changed = await library.verifyAvailability();

      expect(changed, 0);
      final rows = await backend.media.all();
      expect(rows.single.availability, 'available');
    });

    test('melewati baris yang sudah ditandai tidak tersedia', () async {
      final hilang = p.join(storage.mediaDir.path, 'hilang.mp3');
      await backend.media.importDrafts([_draftFor(hilang, 'hilang.mp3')]);
      await backend.media.markUnavailable(
        (await backend.media.all()).single.id,
      );

      final changed = await library.verifyAvailability();

      expect(changed, 0);
    });
  });

  group('MediaLibraryService.importFromPicker', () {
    test(
      'berkas kosong dilaporkan ditolak tanpa membatalkan berkas lain',
      () async {
        final backend = SonoraBackend(SonoraDatabase(NativeDatabase.memory()));
        final baik = await tempPickedFile(root, 'baik.mp3', bytes: 512);
        final kosongPath = File(p.join(root.path, 'sumber-kosong.mp3'))
          ..writeAsBytesSync([]);
        final kosong = PickedMedia(
          fileName: 'kosong.mp3',
          sizeBytes: 0,
          path: kosongPath.path,
        );
        final library = MediaLibraryService(
          backend: backend,
          picker: FakeMediaPicker([baik, kosong]),
          storage: storage,
        );

        final report = await library.importFromPicker(MediaType.audio);

        expect(report.importedCount, 1);
        expect(report.rejectedCount, 1);
        expect(report.outcomes.last.reason, contains('kosong'));
        expect(
          storage.mediaDir.listSync().whereType<File>(),
          hasLength(1),
          reason: 'hanya salinan yang berhasil yang boleh tersisa',
        );
      },
    );
  });
}
