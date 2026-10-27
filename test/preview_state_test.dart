import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/preview_state.dart';

void main() {
  test('pencarian mencocokkan judul, artis, dan album tanpa internet', () {
    final state = PreviewState();
    expect(state.search('midnight').map((item) => item.id), ['song-1']);
    expect(state.search('nara').length, 2);
    expect(state.search('blue hours').map((item) => item.id), ['song-2']);
    expect(state.search('tidak ada'), isEmpty);
    state.dispose();
  });

  test('antrean dapat ditambah, diurutkan, dihapus, dan dikosongkan', () {
    final state = PreviewState();
    expect(state.queue.map((item) => item.id), ['song-2', 'song-3', 'song-4']);
    state.reorderQueue(0, 3);
    expect(state.queue.map((item) => item.id), ['song-3', 'song-4', 'song-2']);
    state.removeFromQueueAt(1);
    expect(state.queue.map((item) => item.id), ['song-3', 'song-2']);
    state.clearQueue();
    expect(state.queue, isEmpty);
    state.dispose();
  });

  test(
    'playlist memvalidasi nama dan memperbarui isi tanpa menghapus media',
    () {
      final state = PreviewState();
      expect(state.createPlaylist('   '), isNotNull);
      expect(state.createPlaylist('late night'), isNotNull);
      expect(state.createPlaylist('  Teman perjalanan  '), isNull);
      final playlist = state.playlists.last;
      expect(playlist.name, 'Teman perjalanan');
      state.addToPlaylist(playlist.id, 'song-4');
      state.addToPlaylist(playlist.id, 'song-4');
      expect(state.songsInPlaylist(playlist.id).map((item) => item.id), [
        'song-4',
      ]);
      expect(state.renamePlaylist(playlist.id, 'Perjalanan pulang'), isNull);
      state.removeFromPlaylist(playlist.id, 'song-4');
      expect(state.songsInPlaylist(playlist.id), isEmpty);
      state.deletePlaylist(playlist.id);
      expect(state.playlistById(playlist.id), isNull);
      expect(state.songs.length, 6);
      state.dispose();
    },
  );

  test(
    'kontrol preview berpindah track dan tidak mengaktifkan playback palsu',
    () {
      final state = PreviewState();
      expect(state.selected?.id, 'song-1');
      expect(state.isPlaying, isFalse);
      state.togglePlay();
      expect(state.isPlaying, isFalse);
      state.seek(10);
      state.previous();
      expect(state.selected?.id, 'song-1');
      expect(state.position, 0);
      state.previous();
      expect(state.selected?.id, 'song-4');
      state.next();
      expect(state.selected?.id, 'song-4');
      state.seek(999);
      expect(state.position, 208);
      state.cycleRepeat();
      expect(state.repeat, PreviewRepeat.one);
      state.toggleFavorite('song-1');
      expect(state.favorites, contains('song-1'));
      state.dispose();
    },
  );

  test('next mengikuti urutan antrean, bukan urutan library', () {
    final state = PreviewState();
    state.select(sampleSongs.first);
    state.reorderQueue(0, 2);
    expect(state.queue.map((item) => item.id), ['song-3', 'song-4', 'song-2']);
    state.next();
    expect(state.selected?.id, 'song-3');
    state.next();
    expect(state.selected?.id, 'song-4');
    state.dispose();
  });

  test('mode repeat mengatur perilaku di ujung antrean', () {
    final state = PreviewState();
    state.select(sampleSongs[3]);
    state.next();
    expect(state.selected?.id, 'song-4');
    state.cycleRepeat();
    expect(state.repeat, PreviewRepeat.one);
    state.next();
    expect(state.selected?.id, 'song-4');
    state.cycleRepeat();
    expect(state.repeat, PreviewRepeat.all);
    state.next();
    expect(state.selected?.id, 'song-2');
    state.dispose();
  });

  test('shuffle memutar antrean secara stabil tanpa kehilangan item', () {
    final state = PreviewState();
    state.toggleShuffle();
    expect(state.shuffle, isTrue);
    final visited = <String>[];
    state.select(state.queue.first);
    for (var step = 0; step < state.queue.length; step++) {
      visited.add(state.selected!.id);
      state.next();
    }
    expect(visited, ['song-2', 'song-4', 'song-3']);
    state.toggleShuffle();
    expect(state.shuffle, isFalse);
    state.next();
    expect(state.selected?.id, 'song-4');
    state.dispose();
  });
}
