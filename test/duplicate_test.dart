import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonora/src/data/backend.dart';
import 'package:sonora/src/data/database.dart';
import 'package:sonora/src/data/models.dart';

/// Menulis berkas sumber dengan isi tertentu agar hash isinya bisa diuji.
File tulisBerkas(Directory root, String nama, List<int> isi) {
  final file = File(p.join(root.path, nama));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(Uint8List.fromList(isi));
  return file;
}

MediaDraft draftUntuk(File file, String fileName, {MediaType? tipe}) =>
    MediaDraft(
      uri: file.path,
      fileName: fileName,
      mediaType: tipe ?? MediaType.audio,
      durationMs: 1000,
      fileSizeBytes: file.lengthSync(),
    );

void main() {
  late Directory root;
  late SonoraBackend backend;

  setUp(() {
    root = Directory.systemTemp.createTempSync('sonora_duplikat_');
    backend = SonoraBackend(SonoraDatabase(NativeDatabase.memory()));
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('deteksi duplikat isi berkas', () {
    test('berkas sama dengan nama berbeda dianggap duplikat', () async {
      final asli = tulisBerkas(root, 'lagu.mp3', List<int>.filled(600, 9));
      final salinan = tulisBerkas(
        root,
        'lagu (1).mp3',
        List<int>.filled(600, 9),
      );

      final pertama = await backend.media.importDrafts([
        draftUntuk(asli, 'lagu.mp3'),
      ]);
      final kedua = await backend.media.importDrafts([
        draftUntuk(salinan, 'lagu (1).mp3'),
      ]);

      expect(pertama.importedCount, 1);
      expect(
        kedua.duplicateCount,
        1,
        reason: 'isi yang sama harus ditolak walau namanya berbeda',
      );
      expect(await backend.media.all(), hasLength(1));
    });

    test('berkas berbeda dengan ukuran sama tetap diterima', () async {
      final satu = tulisBerkas(root, 'satu.mp3', List<int>.filled(600, 1));
      final dua = tulisBerkas(root, 'dua.mp3', List<int>.filled(600, 2));

      final report = await backend.media.importDrafts([
        draftUntuk(satu, 'satu.mp3'),
        draftUntuk(dua, 'dua.mp3'),
      ]);

      expect(
        report.importedCount,
        2,
        reason: 'isi berbeda tidak boleh dianggap duplikat hanya karena ukurannya sama',
      );
      expect(report.duplicateCount, 0);
      expect(await backend.media.all(), hasLength(2));
    });

    test('nama dan ukuran sama tetapi isi berbeda tetap diterima', () async {
      final pertama = tulisBerkas(
        root,
        'v1/lagu.mp3',
        List<int>.filled(600, 3),
      );
      final kedua = tulisBerkas(root, 'v2/lagu.mp3', List<int>.filled(600, 4));

      await backend.media.importDrafts([draftUntuk(pertama, 'lagu.mp3')]);
      final report = await backend.media.importDrafts([
        draftUntuk(kedua, 'lagu.mp3'),
      ]);

      expect(
        report.importedCount,
        1,
        reason: 'nama sama belum tentu berkas yang sama',
      );
      expect(await backend.media.all(), hasLength(2));
    });

    test('berkas lama yang sudah hilang tidak menggagalkan impor', () async {
      final lama = tulisBerkas(root, 'hilang.mp3', List<int>.filled(600, 5));
      await backend.media.importDrafts([draftUntuk(lama, 'hilang.mp3')]);
      lama.deleteSync();

      final baru = tulisBerkas(root, 'baru.mp3', List<int>.filled(600, 6));
      final report = await backend.media.importDrafts([
        draftUntuk(baru, 'baru.mp3'),
      ]);

      expect(report.importedCount, 1);
    });
  });
}
