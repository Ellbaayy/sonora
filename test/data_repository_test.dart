import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/data/database.dart';
import 'package:sonora/src/data/models.dart';
import 'package:sonora/src/data/repositories.dart';

MediaDraft draft(
  String fileName, {
  String? uri,
  MediaType type = MediaType.audio,
  String? title,
  String? artist,
  String? mimeType,
  int? size,
}) => MediaDraft(
  uri: uri ?? 'content://media/$fileName',
  fileName: fileName,
  mediaType: type,
  title: title,
  artist: artist,
  mimeType: mimeType,
  fileSizeBytes: size,
);

void main() {
  late SonoraDatabase db;
  late MediaRepository media;
  late PlaylistRepository playlists;
  late QueueRepository queue;
  late PlaybackStateRepository playback;
  late SettingsRepository settings;
  var counter = 0;
  var now = DateTime.utc(2026, 10, 27, 12);

  setUp(() {
    counter = 0;
    now = DateTime.utc(2026, 10, 27, 12);
    db = SonoraDatabase(NativeDatabase.memory());
    media = MediaRepository(
      db,
      clock: () => now,
      idGenerator: () => 'm${++counter}',
    );
    playlists = PlaylistRepository(
      db,
      clock: () => now,
      idGenerator: () => 'p${++counter}',
    );
    queue = QueueRepository(db, idGenerator: () => 'q${++counter}');
    playback = PlaybackStateRepository(db, clock: () => now);
    settings = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>> seedSongs([int count = 3]) async {
    final drafts = [
      for (var index = 0; index < count; index++)
        draft(
          'lagu-$index.mp3',
          title: 'Lagu $index',
          artist: 'Artis $index',
          size: 1000 * (index + 1),
        ),
    ];
    final report = await media.importDrafts(drafts);
    expect(report.importedCount, count);
    return (await media.all()).map((row) => row.id).toList();
  }

  group('impor media', () {
    test(
      'menyimpan metadata dan memakai nama berkas sebagai fallback',
      () async {
        final report = await media.importDrafts([
          draft('Tanpa Judul.mp3'),
          draft('dengan-tag.mp3', title: 'Judul Asli', artist: 'Nara'),
          draft('klip.mp4', type: MediaType.video),
        ]);

        expect(report.importedCount, 3);
        expect(report.duplicateCount, 0);
        expect(report.rejectedCount, 0);

        final rows = await media.all();
        final fallback = rows.firstWhere(
          (row) => row.fileName == 'Tanpa Judul.mp3',
        );
        expect(fallback.title, 'Tanpa Judul');
        expect(fallback.availability, 'available');
        expect(fallback.playCount, 0);
        expect(fallback.dateAdded, now.millisecondsSinceEpoch);

        final tagged = rows.firstWhere(
          (row) => row.fileName == 'dengan-tag.mp3',
        );
        expect(tagged.title, 'Judul Asli');
        expect(tagged.artist, 'Nara');

        expect(await media.all(type: MediaType.video), hasLength(1));
      },
    );

    test(
      'menolak duplikat, format tak didukung, dan MIME yang salah',
      () async {
        await seedSongs(1);
        final report = await media.importDrafts([
          draft('lagu-0.mp3', title: 'Lagu 0'),
          draft('lagu-0.mp3', uri: 'content://lain/lagu-0.mp3', size: 1000),
          draft('dokumen.pdf'),
          draft('lagu-9.mp3', mimeType: 'video/mp4'),
          draft('lagu-8.mp3', size: -5),
        ]);

        expect(report.importedCount, 0);
        expect(report.duplicateCount, 2);
        expect(report.rejectedCount, 3);
        expect(
          report.rejected.map((outcome) => outcome.reason),
          contains('MIME type tidak sesuai dengan jenis media.'),
        );
        expect(await media.all(), hasLength(1));
      },
    );

    test('pencarian lokal mencocokkan judul, artis, dan nama berkas', () async {
      await media.importDrafts([
        draft('malam.mp3', title: 'Midnight in Jakarta', artist: 'Nara'),
        draft('pagi.mp3', title: 'Pagi Cerah', artist: 'Kala'),
      ]);

      expect(
        (await media.search('midnight')).single.title,
        'Midnight in Jakarta',
      );
      expect((await media.search('kala')).single.fileName, 'pagi.mp3');
      expect((await media.search('  ')), hasLength(2));
      expect(await media.search('tidak-ada'), isEmpty);
    });

    test('menandai berkas hilang tanpa menghapus record', () async {
      final ids = await seedSongs(1);
      await media.markUnavailable(ids.first);
      final row = await media.byId(ids.first);
      expect(row!.availability, 'unavailable');
      expect(await media.all(), hasLength(1));
      expect(await media.removeUnavailable(), 1);
      expect(await media.all(), isEmpty);
    });

    test('menghapus media ikut membersihkan playlist dan antrean', () async {
      final ids = await seedSongs(2);
      final playlist = await playlists.create('Malam');
      await playlists.addTrack(playlist.id, ids.first);
      await queue.enqueue(ids.first);
      await queue.enqueue(ids.last);

      expect(await media.removeFromLibrary(ids.first), 1);

      expect(await playlists.tracks(playlist.id), isEmpty);
      expect((await queue.items()).map((row) => row.id), [ids.last]);
      expect(await media.all(), hasLength(1));
    });
  });

  group('playlist', () {
    test('validasi nama dan operasi transaksional', () async {
      await expectLater(
        playlists.create('   '),
        throwsA(isA<SonoraDataException>()),
      );
      final playlist = await playlists.create('  Teman perjalanan  ');
      expect(playlist.name, 'Teman perjalanan');

      final ids = await seedSongs(3);
      for (final id in ids) {
        await playlists.addTrack(playlist.id, id);
      }
      await expectLater(
        playlists.addTrack(playlist.id, ids.first),
        throwsA(isA<SonoraDataException>()),
      );

      expect((await playlists.tracks(playlist.id)).map((row) => row.id), ids);

      await playlists.reorder(playlist.id, 0, 2);
      expect((await playlists.tracks(playlist.id)).map((row) => row.id), [
        ids[1],
        ids[2],
        ids[0],
      ]);

      await playlists.removeTrack(playlist.id, ids[2]);
      expect((await playlists.tracks(playlist.id)).map((row) => row.id), [
        ids[1],
        ids[0],
      ]);

      final positions = await db
          .customSelect('SELECT position FROM playlist_items ORDER BY position')
          .get();
      expect(positions.map((row) => row.read<int>('position')), [0, 1]);
    });

    test('menghapus playlist tidak menghapus media sumber', () async {
      final ids = await seedSongs(1);
      final playlist = await playlists.create('Sementara');
      await playlists.addTrack(playlist.id, ids.first);

      await playlists.delete(playlist.id);

      expect(await playlists.byId(playlist.id), isNull);
      expect(await media.all(), hasLength(1));
      final orphans = await db.select(db.playlistItems).get();
      expect(orphans, isEmpty);
    });

    test('ringkasan playlist memuat jumlah track', () async {
      final ids = await seedSongs(2);
      final first = await playlists.create('Satu');
      await playlists.addTrack(first.id, ids.first);
      await playlists.addTrack(first.id, ids.last);
      await playlists.create('Dua');

      final summaries = await playlists.summaries();
      expect(
        summaries.firstWhere((item) => item.playlist.id == first.id).trackCount,
        2,
      );
      expect(
        summaries.firstWhere((item) => item.playlist.name == 'Dua').trackCount,
        0,
      );
    });

    test(
      'mengubah nama memperbarui updated_at dan menolak nama kosong',
      () async {
        final playlist = await playlists.create('Awal');
        now = now.add(const Duration(minutes: 5));
        await playlists.rename(playlist.id, '  Baru  ');

        final updated = await playlists.byId(playlist.id);
        expect(updated!.name, 'Baru');
        expect(updated.updatedAt, now.millisecondsSinceEpoch);
        expect(updated.createdAt, lessThan(updated.updatedAt));
        await expectLater(
          playlists.rename(playlist.id, '  '),
          throwsA(isA<SonoraDataException>()),
        );
        await expectLater(
          playlists.rename('tidak-ada', 'X'),
          throwsA(isA<SonoraDataException>()),
        );
      },
    );
  });

  group('antrean', () {
    test('enqueue tidak mengganti item aktif dan posisi tetap rapat', () async {
      final ids = await seedSongs(3);
      for (final id in ids) {
        await queue.enqueue(id);
      }
      expect((await queue.items()).map((row) => row.id), ids);

      await queue.removeAt(1);
      expect((await queue.items()).map((row) => row.id), [ids[0], ids[2]]);

      await queue.reorder(0, 1);
      expect((await queue.items()).map((row) => row.id), [ids[2], ids[0]]);

      final positions = await db
          .customSelect('SELECT position FROM queue_items ORDER BY position')
          .get();
      expect(positions.map((row) => row.read<int>('position')), [0, 1]);

      await queue.clear();
      expect(await queue.items(), isEmpty);
    });

    test('menolak media yang tidak ada dan sumber tak dikenal', () async {
      final ids = await seedSongs(1);
      await expectLater(
        queue.enqueue('tidak-ada'),
        throwsA(isA<SonoraDataException>()),
      );
      await expectLater(
        queue.enqueue(ids.first, sourceType: 'cloud'),
        throwsA(isA<SonoraDataException>()),
      );
      await expectLater(queue.removeAt(4), throwsA(isA<SonoraDataException>()));
    });
  });

  group('state pemutaran dan pengaturan', () {
    test('baris tunggal dibuat otomatis lalu tersimpan', () async {
      final initial = await playback.read();
      expect(initial.id, 1);
      expect(initial.currentMediaId, isNull);
      expect(initial.repeatMode, 'off');

      final ids = await seedSongs(1);
      await playback.save(
        currentMediaId: ids.first,
        positionMs: 42000,
        repeatMode: 'all',
        shuffleEnabled: true,
        volume: 0.6,
      );

      final saved = await playback.read();
      expect(saved.currentMediaId, ids.first);
      expect(saved.positionMs, 42000);
      expect(saved.repeatMode, 'all');
      expect(saved.shuffleEnabled, isTrue);
      expect(saved.volume, closeTo(0.6, 1e-9));
      expect(saved.updatedAt, now.millisecondsSinceEpoch);
    });

    test('menolak nilai yang tidak valid', () async {
      await expectLater(
        playback.save(positionMs: -1),
        throwsA(isA<SonoraDataException>()),
      );
      await expectLater(
        playback.save(repeatMode: 'loop'),
        throwsA(isA<SonoraDataException>()),
      );
      await expectLater(
        playback.save(volume: 1.5),
        throwsA(isA<SonoraDataException>()),
      );
    });

    test('pengaturan key-value bertipe dan tahan key kosong', () async {
      expect(await settings.readBool(SettingsKeys.reduceMotion), isFalse);
      await settings.writeBool(SettingsKeys.reduceMotion, true);
      expect(await settings.readBool(SettingsKeys.reduceMotion), isTrue);
      await settings.write(SettingsKeys.volume, '0.4');
      expect(await settings.read(SettingsKeys.volume), '0.4');
      await settings.remove(SettingsKeys.volume);
      expect(await settings.read(SettingsKeys.volume), isNull);
      await expectLater(
        settings.write('  ', 'x'),
        throwsA(isA<SonoraDataException>()),
      );
    });
  });

  test(
    'data bertahan setelah koneksi database ditutup dan dibuka ulang',
    () async {
      final directory = await Directory.systemTemp.createTemp('sonora-db-test');
      final file = File('${directory.path}/sonora.sqlite');

      final first = SonoraDatabase(NativeDatabase(file));
      final mediaRepo = MediaRepository(first, idGenerator: () => 'persist-1');
      final playlistRepo = PlaylistRepository(first, idGenerator: () => 'pl-1');
      final report = await mediaRepo.importDrafts([draft('tahan.mp3')]);
      expect(report.importedCount, 1);
      final playlist = await playlistRepo.create('Awet');
      await playlistRepo.addTrack(playlist.id, 'persist-1');
      await SettingsRepository(first).writeBool(SettingsKeys.cyanAccent, true);
      await first.close();

      final second = SonoraDatabase(NativeDatabase(file));
      addTearDown(() async {
        await second.close();
        await directory.delete(recursive: true);
      });

      final rows = await MediaRepository(second).all();
      expect(rows.single.fileName, 'tahan.mp3');
      expect(
        (await PlaylistRepository(second).tracks('pl-1')).single.id,
        'persist-1',
      );
      expect(
        await SettingsRepository(second).readBool(SettingsKeys.cyanAccent),
        isTrue,
      );
    },
  );
}
