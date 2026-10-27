import 'package:flutter/foundation.dart';

import 'data/repositories.dart';

enum MediaKind { audio, video }

enum ArtworkStyle { waves, orbital, bloom, midnight, cinema, cassette }

enum PreviewRepeat { off, one, all }

@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.style,
    this.kind = MediaKind.audio,
  });
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final ArtworkStyle style;
  final MediaKind kind;
}

@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.trackIds,
  });
  final String id;
  final String name;
  final List<String> trackIds;
}

const sampleSongs = <MediaItem>[
  MediaItem(
    id: 'song-1',
    title: 'Midnight in Jakarta',
    artist: 'Nara',
    album: 'City Lights',
    duration: 224,
    style: ArtworkStyle.waves,
  ),
  MediaItem(
    id: 'song-2',
    title: 'Blue Hours',
    artist: 'Nara',
    album: 'Blue Hours',
    duration: 197,
    style: ArtworkStyle.midnight,
  ),
  MediaItem(
    id: 'song-3',
    title: 'Slow Orbit',
    artist: 'Aster',
    album: 'Afterglow',
    duration: 241,
    style: ArtworkStyle.orbital,
  ),
  MediaItem(
    id: 'song-4',
    title: 'Room to Breathe',
    artist: 'Lumen',
    album: 'Still Here',
    duration: 208,
    style: ArtworkStyle.bloom,
  ),
  MediaItem(
    id: 'song-5',
    title: 'Analog Sunday',
    artist: 'Kala',
    album: 'Soft Focus',
    duration: 185,
    style: ArtworkStyle.cassette,
  ),
  MediaItem(
    id: 'song-6',
    title: 'The Way Home',
    artist: 'Lumen',
    album: 'Still Here',
    duration: 216,
    style: ArtworkStyle.waves,
  ),
];

const sampleVideos = <MediaItem>[
  MediaItem(
    id: 'video-1',
    title: 'Evening in Motion',
    artist: 'Video contoh',
    album: 'Koleksi video',
    duration: 86,
    style: ArtworkStyle.cinema,
    kind: MediaKind.video,
  ),
  MediaItem(
    id: 'video-2',
    title: 'Shapes of Light',
    artist: 'Video contoh',
    album: 'Koleksi video',
    duration: 124,
    style: ArtworkStyle.orbital,
    kind: MediaKind.video,
  ),
  MediaItem(
    id: 'video-3',
    title: 'After the Rain',
    artist: 'Video contoh',
    album: 'Koleksi video',
    duration: 97,
    style: ArtworkStyle.bloom,
    kind: MediaKind.video,
  ),
  MediaItem(
    id: 'video-4',
    title: 'City Sketches',
    artist: 'Video contoh',
    album: 'Koleksi video',
    duration: 148,
    style: ArtworkStyle.midnight,
    kind: MediaKind.video,
  ),
];

class PreviewState extends ChangeNotifier {
  PreviewState({this.settings});

  /// Penyimpanan preferensi lokal; `null` berarti mode tanpa persistensi.
  final SettingsRepository? settings;

  int _tab = 0;
  String? _selectedId = 'song-1';
  bool _isPlaying = false;
  double _position = 42;
  double _volume = .72;
  bool _shuffle = false;
  PreviewRepeat _repeat = PreviewRepeat.off;
  bool _reduceMotion = false;
  bool _cyanAccent = false;
  bool _previewMode = true;
  String _sort = 'Terbaru ditambahkan';
  final Set<String> _favorites = {'song-2'};
  final Set<String> _hiddenIds = {};
  final List<String> _queue = ['song-2', 'song-3', 'song-4'];
  List<String>? _shuffleOrder;
  List<Playlist> _playlists = [
    const Playlist(
      id: 'playlist-1',
      name: 'Late Night',
      trackIds: ['song-1', 'song-2', 'song-3'],
    ),
    const Playlist(
      id: 'playlist-2',
      name: 'Easy Sunday',
      trackIds: ['song-4', 'song-5'],
    ),
  ];

  int get tab => _tab;
  MediaItem? get selected => itemById(_selectedId);
  bool get isPlaying => _isPlaying;
  double get position => _position.clamp(0, selected?.duration.toDouble() ?? 0);
  double get volume => _volume;
  bool get shuffle => _shuffle;
  PreviewRepeat get repeat => _repeat;
  bool get reduceMotion => _reduceMotion;
  bool get cyanAccent => _cyanAccent;
  bool get previewMode => _previewMode;
  String get sort => _sort;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<MediaItem> get songs =>
      sampleSongs.where((song) => !_hiddenIds.contains(song.id)).toList();
  List<MediaItem> get videos =>
      sampleVideos.where((video) => !_hiddenIds.contains(video.id)).toList();
  List<MediaItem> get queue => _queue
      .map(itemById)
      .whereType<MediaItem>()
      .where((song) => !_hiddenIds.contains(song.id))
      .toList();
  bool get hasSelection => selected != null;

  MediaItem? itemById(String? id) {
    for (final item in [...sampleSongs, ...sampleVideos]) {
      if (item.id == id) return item;
    }
    return null;
  }

  Playlist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  List<MediaItem> songsInPlaylist(String id) {
    final playlist = playlistById(id);
    if (playlist == null) return [];
    return playlist.trackIds
        .map(itemById)
        .whereType<MediaItem>()
        .where((song) => !_hiddenIds.contains(song.id))
        .toList();
  }

  List<MediaItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return songs;
    return songs
        .where(
          (song) => [
            song.title,
            song.artist,
            song.album,
            song.id,
          ].any((field) => field.toLowerCase().contains(normalized)),
        )
        .toList();
  }

  void setTab(int value) {
    if (_tab == value) return;
    _tab = value;
    notifyListeners();
  }

  void select(MediaItem item, {bool openPlayer = true}) {
    if (_hiddenIds.contains(item.id)) return;
    _selectedId = item.id;
    _position = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlay() {
    if (selected == null || _previewMode) return;
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void next() {
    final order = _playbackOrder;
    final current = selected;
    if (order.isEmpty || current == null) return;
    if (_repeat == PreviewRepeat.one) {
      _position = 0;
      notifyListeners();
      return;
    }
    final index = order.indexWhere((item) => item.id == current.id);
    if (index == -1) {
      _startPlayback(order.first);
      return;
    }
    if (index + 1 < order.length) {
      _startPlayback(order[index + 1]);
      return;
    }
    if (_repeat == PreviewRepeat.all) {
      _startPlayback(order.first);
      return;
    }
    // Ujung antrean dengan repeat nonaktif: playback berhenti pada item terakhir.
    _position = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void previous() {
    final current = selected;
    if (_position > 3 || current == null) {
      _position = 0;
      notifyListeners();
      return;
    }
    final order = _playbackOrder;
    if (order.isEmpty) return;
    final index = order.indexWhere((item) => item.id == current.id);
    if (index == -1) {
      _startPlayback(order.last);
      return;
    }
    if (index - 1 >= 0) {
      _startPlayback(order[index - 1]);
      return;
    }
    if (_repeat == PreviewRepeat.all) {
      _startPlayback(order.last);
      return;
    }
    _position = 0;
    _isPlaying = false;
    notifyListeners();
  }

  /// Urutan playback mengikuti antrean bila terisi, lalu library, dan
  /// menerapkan shuffle yang stabil selama status shuffle aktif.
  List<MediaItem> get _playbackOrder {
    final items = queue.isNotEmpty ? queue : songs;
    final order = _shuffleOrder;
    if (!_shuffle || order == null || items.length < 2) return items;
    final sorted = <MediaItem>[];
    final used = <int>{};
    for (final id in order) {
      for (var index = 0; index < items.length; index++) {
        if (!used.contains(index) && items[index].id == id) {
          used.add(index);
          sorted.add(items[index]);
          break;
        }
      }
    }
    for (var index = 0; index < items.length; index++) {
      if (!used.contains(index)) sorted.add(items[index]);
    }
    return sorted;
  }

  List<String> _buildShuffleOrder() {
    final ids = <String>[
      for (final item in (queue.isNotEmpty ? queue : songs)) item.id,
    ];
    // Fisher-Yates dengan seed tetap agar urutan preview stabil antar rebuild.
    var seed = 12345;
    for (var index = ids.length - 1; index > 0; index--) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final swapWith = seed % (index + 1);
      final buffer = ids[index];
      ids[index] = ids[swapWith];
      ids[swapWith] = buffer;
    }
    return ids;
  }

  void _startPlayback(MediaItem item) {
    _selectedId = item.id;
    _position = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void seek(double value) {
    _position = value.clamp(0, selected?.duration.toDouble() ?? 0);
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0, 1);
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _shuffleOrder = _shuffle ? _buildShuffleOrder() : null;
    notifyListeners();
    _persist((settings) => settings.writeBool(SettingsKeys.shuffle, _shuffle));
  }

  void cycleRepeat() {
    _repeat =
        PreviewRepeat.values[(_repeat.index + 1) % PreviewRepeat.values.length];
    notifyListeners();
    _persist(
      (settings) => settings.write(SettingsKeys.repeatMode, _repeat.name),
    );
  }

  void toggleFavorite(String id) {
    if (!_favorites.add(id)) _favorites.remove(id);
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    notifyListeners();
    _persist(
      (settings) => settings.writeBool(SettingsKeys.reduceMotion, value),
    );
  }

  void setAccent(bool cyan) {
    _cyanAccent = cyan;
    notifyListeners();
    _persist((settings) => settings.writeBool(SettingsKeys.cyanAccent, cyan));
  }

  /// Memulihkan preferensi yang tersimpan agar bertahan setelah aplikasi
  /// ditutup dan dibuka kembali (PRD bagian 6.7).
  Future<void> restorePreferences() async {
    final settings = this.settings;
    if (settings == null) return;
    try {
      final cyan = await settings.readBool(SettingsKeys.cyanAccent);
      final reduceMotion = await settings.readBool(SettingsKeys.reduceMotion);
      final shuffle = await settings.readBool(SettingsKeys.shuffle);
      final repeat = await settings.read(SettingsKeys.repeatMode);
      _cyanAccent = cyan;
      _reduceMotion = reduceMotion;
      _shuffle = shuffle;
      _shuffleOrder = shuffle ? _buildShuffleOrder() : null;
      _repeat = PreviewRepeat.values.firstWhere(
        (value) => value.name == repeat,
        orElse: () => PreviewRepeat.off,
      );
      notifyListeners();
    } catch (error) {
      debugPrint('SONORA: preferensi tersimpan tidak dapat dibaca ($error)');
    }
  }

  void _persist(Future<void> Function(SettingsRepository settings) operation) {
    final settings = this.settings;
    if (settings == null) return;
    operation(settings).catchError((Object error) {
      debugPrint('SONORA: preferensi gagal disimpan ($error)');
    });
  }

  void setSort(String value) {
    _sort = value;
    notifyListeners();
  }

  void enqueue(String id) {
    if (itemById(id) == null || _hiddenIds.contains(id)) return;
    _queue.add(id);
    notifyListeners();
  }

  void removeFromQueueAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    final boundedIndex = newIndex.clamp(0, _queue.length);
    final item = _queue.removeAt(oldIndex);
    _queue.insert(boundedIndex.clamp(0, _queue.length), item);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  String? createPlaylist(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Nama playlist tidak boleh kosong.';
    if (_playlists.any(
      (playlist) => playlist.name.toLowerCase() == normalized.toLowerCase(),
    )) {
      return 'Nama playlist sudah digunakan.';
    }
    _playlists = [
      ..._playlists,
      Playlist(
        id: 'playlist-${DateTime.now().microsecondsSinceEpoch}',
        name: normalized,
        trackIds: const [],
      ),
    ];
    notifyListeners();
    return null;
  }

  String? renamePlaylist(String id, String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Nama playlist tidak boleh kosong.';
    if (_playlists.any(
      (playlist) =>
          playlist.id != id &&
          playlist.name.toLowerCase() == normalized.toLowerCase(),
    )) {
      return 'Nama playlist sudah digunakan.';
    }
    _playlists = _playlists
        .map(
          (playlist) => playlist.id == id
              ? Playlist(id: id, name: normalized, trackIds: playlist.trackIds)
              : playlist,
        )
        .toList();
    notifyListeners();
    return null;
  }

  void deletePlaylist(String id) {
    _playlists = _playlists.where((playlist) => playlist.id != id).toList();
    notifyListeners();
  }

  void addToPlaylist(String playlistId, String songId) {
    _playlists = _playlists.map((playlist) {
      if (playlist.id != playlistId ||
          playlist.trackIds.contains(songId) ||
          itemById(songId) == null) {
        return playlist;
      }
      return Playlist(
        id: playlist.id,
        name: playlist.name,
        trackIds: [...playlist.trackIds, songId],
      );
    }).toList();
    notifyListeners();
  }

  void removeFromPlaylist(String playlistId, String songId) {
    _playlists = _playlists
        .map(
          (playlist) => playlist.id == playlistId
              ? Playlist(
                  id: playlist.id,
                  name: playlist.name,
                  trackIds: playlist.trackIds
                      .where((id) => id != songId)
                      .toList(),
                )
              : playlist,
        )
        .toList();
    notifyListeners();
  }

  void hideMedia(String id) {
    _hiddenIds.add(id);
    _queue.remove(id);
    _playlists = _playlists
        .map(
          (playlist) => Playlist(
            id: playlist.id,
            name: playlist.name,
            trackIds: playlist.trackIds
                .where((trackId) => trackId != id)
                .toList(),
          ),
        )
        .toList();
    if (_selectedId == id) {
      _selectedId = null;
      _isPlaying = false;
      _position = 0;
    }
    notifyListeners();
  }

  void showPreview() {
    _previewMode = true;
    _hiddenIds.clear();
    _selectedId ??= 'song-1';
    notifyListeners();
  }

  void showEmptyLibrary() {
    _previewMode = false;
    _isPlaying = false;
    notifyListeners();
  }
}

String formatDuration(num seconds) {
  final value = seconds.toInt();
  return '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
}
