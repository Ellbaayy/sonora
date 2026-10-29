import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/app_state.dart';
import 'package:sonora/src/media/media_item.dart';
import 'package:sonora/src/playback/audio_engine.dart';

import 'helpers.dart';

void main() {
  test('library hanya memuat media yang benar-benar diimpor', () async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Alpha', artist: 'Nara'),
        audioDraft('b.mp3', title: 'Beta', artist: 'Aster'),
        videoDraft('c.mp4', title: 'Klip'),
      ],
    );
    addTearDown(harness.close);

    expect(
      harness.state.songs.map((song) => song.title),
      containsAll(['Alpha', 'Beta']),
    );
    expect(harness.state.videos.map((video) => video.title), ['Klip']);
    expect(harness.state.songs, hasLength(2));
    expect(harness.state.itemById(harness.state.songs.first.id), isNotNull);
    expect(harness.state.songs.first.artist, isNotEmpty);
  });

  test('memutar media memuat berkas dan mencatat riwayat', () async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Alpha')],
    );
    addTearDown(harness.close);
    final song = harness.state.songs.single;

    await harness.state.playItem(song);

    expect(harness.state.selected?.id, song.id);
    expect(harness.state.isPlaying, isTrue);
    expect(harness.engine.lastLoadedUri, song.uri);
    final row = await harness.backend.media.byId(song.id);
    expect(row!.playCount, 1);
    expect(row.lastPlayedAt, isNotNull);

    await harness.state.togglePlay();
    expect(harness.state.isPlaying, isFalse);
  });

  test(
    'next mengikuti antrean dan berhenti di ujung saat repeat mati',
    () async {
      final harness = await createHarness(
        seeds: [
          audioDraft('a.mp3', title: 'Alpha'),
          audioDraft('b.mp3', title: 'Beta'),
          audioDraft('c.mp3', title: 'Gamma'),
        ],
      );
      addTearDown(harness.close);
      final songs = harness.state.songs;
      final beta = songs.firstWhere((song) => song.title == 'Beta');
      final gamma = songs.firstWhere((song) => song.title == 'Gamma');

      await harness.state.enqueue(beta.id);
      await harness.state.enqueue(gamma.id);
      await harness.state.playItem(beta);

      await harness.state.next();
      expect(harness.state.selected?.id, gamma.id);
      expect(harness.state.isPlaying, isTrue);

      await harness.state.next();
      expect(harness.state.selected?.id, gamma.id);
      expect(harness.state.isPlaying, isFalse);
      expect(harness.state.position, Duration.zero);
    },
  );

  test(
    'repeat all kembali ke awal dan repeat one mengulang lagu aktif',
    () async {
      final harness = await createHarness(
        seeds: [
          audioDraft('a.mp3', title: 'Alpha'),
          audioDraft('b.mp3', title: 'Beta'),
        ],
      );
      addTearDown(harness.close);
      final alpha = harness.state.songs.firstWhere((s) => s.title == 'Alpha');
      final beta = harness.state.songs.firstWhere((s) => s.title == 'Beta');

      await harness.state.cycleRepeat();
      expect(harness.state.repeat, SonoraRepeat.one);
      await harness.state.playItem(beta);
      await harness.state.next();
      expect(harness.state.selected?.id, beta.id);

      await harness.state.cycleRepeat();
      expect(harness.state.repeat, SonoraRepeat.all);
      await harness.state.next();
      expect(harness.state.selected?.id, alpha.id);
    },
  );

  test('penyelesaian trek lanjut ke lagu berikutnya', () async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Alpha'),
        audioDraft('b.mp3', title: 'Beta'),
      ],
    );
    addTearDown(harness.close);
    final alpha = harness.state.songs.firstWhere((s) => s.title == 'Alpha');
    final beta = harness.state.songs.firstWhere((s) => s.title == 'Beta');
    await harness.state.enqueue(beta.id);

    await harness.state.playItem(alpha);
    harness.engine.emitCompleted();
    await pumpEventQueue(times: 8);

    expect(harness.state.selected?.id, beta.id);
  });

  test(
    'shuffle mempertahankan semua item dan stabil antar pemutaran',
    () async {
      final harness = await createHarness(
        seeds: [
          audioDraft('a.mp3', title: 'Alpha'),
          audioDraft('b.mp3', title: 'Beta'),
          audioDraft('c.mp3', title: 'Gamma'),
          audioDraft('d.mp3', title: 'Delta'),
        ],
      );
      addTearDown(harness.close);
      final songs = harness.state.songs;
      await harness.state.toggleShuffle();
      expect(harness.state.shuffle, isTrue);
      // Repeat all agar putaran melewati seluruh urutan acak; repeat off akan
      // berhenti di ujung urutan dari posisi lagu yang sedang diputar.
      await harness.state.cycleRepeat();
      await harness.state.cycleRepeat();
      expect(harness.state.repeat, SonoraRepeat.all);

      Future<List<String>> walk() async {
        await harness.state.playItem(songs.first);
        final sequence = <String>[harness.state.selected!.id];
        for (var index = 0; index < songs.length - 1; index++) {
          await harness.state.next();
          sequence.add(harness.state.selected!.id);
        }
        return sequence;
      }

      final firstPass = await walk();
      expect(firstPass.toSet(), hasLength(songs.length));
      final secondPass = await walk();
      expect(secondPass, firstPass, reason: 'urutan acak stabil antar putaran');
    },
  );

  test(
    'antrean, playlist, dan posisi bertahan setelah state dibuat ulang',
    () async {
      final harness = await createHarness(
        seeds: [
          audioDraft('a.mp3', title: 'Alpha'),
          audioDraft('b.mp3', title: 'Beta'),
        ],
      );
      addTearDown(harness.close);
      final songs = harness.state.songs;
      final alpha = songs.firstWhere((s) => s.title == 'Alpha');
      final beta = songs.firstWhere((s) => s.title == 'Beta');

      expect(await harness.state.createPlaylist('Malam'), isNull);
      final playlist = harness.state.playlists.single;
      await harness.state.addToPlaylist(playlist.id, beta.id);
      await harness.state.enqueue(alpha.id);
      await harness.state.enqueue(beta.id);
      await harness.state.playItem(alpha);
      await harness.state.seek(const Duration(seconds: 30));
      await harness.state.flushPlaybackState();

      final restarted = SonoraState(
        FakeAudioEngine(),
        backend: harness.backend,
        library: harness.state.library,
      );
      addTearDown(restarted.dispose);
      await restarted.init();

      expect(restarted.queueIds, [alpha.id, beta.id]);
      expect(restarted.playlists.single.name, 'Malam');
      expect(
        restarted.songsInPlaylist(restarted.playlists.single.id).single.id,
        beta.id,
      );
      expect(restarted.selected?.id, alpha.id);
      expect(restarted.position.inSeconds, 30);
      expect(restarted.isPlaying, isFalse, reason: 'pemulihan tidak autoplay');
    },
  );

  test(
    'impor menyalin berkas, melewati duplikat, dan menolak format asing',
    () async {
      final harness = await createHarness(
        seeds: [audioDraft('lagu.mp3', title: 'Lagu', sizeBytes: 512)],
      );
      addTearDown(harness.close);
      final duplicate = await tempPickedFile(
        harness.root,
        'lagu.mp3',
        bytes: 512,
      );
      final fresh = await tempPickedFile(harness.root, 'baru.mp3', bytes: 900);
      final unsupported = await tempPickedFile(harness.root, 'aneh.txt');
      harness.picker.files = [duplicate, fresh, unsupported];

      final report = await harness.state.importMedia(MediaKind.audio);

      expect(report, isNotNull);
      expect(report!.importedCount, 1);
      expect(report.duplicateCount, 1);
      expect(report.rejectedCount, 1);
      expect(harness.state.songs, hasLength(2));
      expect(harness.state.songs.map((song) => song.title), contains('baru'));

      // Hanya salinan berkas yang berhasil diimpor yang tersisa di penyimpanan.
      final copies = harness.storage.mediaDir.listSync().whereType<File>();
      expect(copies, hasLength(1));
    },
  );

  test('menghapus media membersihkan relasi dan salinan aplikasi', () async {
    final harness = await createHarness();
    addTearDown(harness.close);
    final picked = await tempPickedFile(harness.root, 'hapus.mp3', bytes: 700);
    harness.picker.files = [picked];
    await harness.state.importMedia(MediaKind.audio);
    final song = harness.state.songs.single;

    await harness.state.createPlaylist('Uji');
    await harness.state.addToPlaylist(
      harness.state.playlists.single.id,
      song.id,
    );
    await harness.state.enqueue(song.id);
    final row = await harness.backend.media.byId(song.id);
    final copyPath = row!.uri;
    expect(File(copyPath).existsSync(), isTrue);

    await harness.state.removeFromLibrary(song.id);

    expect(harness.state.songs, isEmpty);
    expect(harness.state.queueIds, isEmpty);
    expect(
      harness.state.songsInPlaylist(harness.state.playlists.single.id),
      isEmpty,
    );
    expect(await harness.backend.media.byId(song.id), isNull);
    expect(
      File(copyPath).existsSync(),
      isFalse,
      reason: 'salinan aplikasi dihapus',
    );
    expect(
      File(picked.path!).existsSync(),
      isTrue,
      reason: 'berkas asli tetap ada',
    );
  });

  test(
    'playCollection mengisi antrean dari playlist lalu memutar item pertama',
    () async {
      final harness = await createHarness(
        seeds: [
          audioDraft('a.mp3', title: 'Alpha'),
          audioDraft('b.mp3', title: 'Beta'),
        ],
      );
      addTearDown(harness.close);
      final songs = harness.state.songs;

      await harness.state.playCollection(songs);

      expect(harness.state.queueIds, [for (final song in songs) song.id]);
      expect(harness.state.selected?.id, songs.first.id);
      expect(harness.state.isPlaying, isTrue);
    },
  );

  test('pencarian lokal mencocokkan judul, artis, dan album', () async {
    final harness = await createHarness(
      seeds: [
        audioDraft('a.mp3', title: 'Midnight', artist: 'Nara', album: 'City'),
        audioDraft(
          'b.mp3',
          title: 'Blue Hours',
          artist: 'Aster',
          album: 'Night',
        ),
      ],
    );
    addTearDown(harness.close);

    expect(harness.state.search('midnight').single.title, 'Midnight');
    expect(harness.state.search('aster').single.title, 'Blue Hours');
    expect(harness.state.search('city').single.title, 'Midnight');
    expect(harness.state.search('tidak-ada'), isEmpty);
  });
}
