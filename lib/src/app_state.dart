import 'dart:async';

import 'package:flutter/widgets.dart';

import 'data/backend.dart';
import 'data/database.dart';
import 'data/models.dart';
import 'data/repositories.dart';
import 'media/media_item.dart';
import 'media/media_library.dart';
import 'playback/audio_engine.dart';

/// Mode pengulangan pemutaran.
enum SonoraRepeat { off, one, all }

/// Playlist lokal beserta urutan track-nya.
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

/// Ringkasan pemakaian penyimpanan untuk layar Pengaturan.
@immutable
class StorageSummary {
  const StorageSummary({
    required this.audioCount,
    required this.videoCount,
    required this.bytes,
  });

  final int audioCount;
  final int videoCount;
  final int bytes;
}

/// Status aplikasi: library, playlist, antrean, preferensi, dan pemutaran.
///
/// Seluruh data disimpan di database lokal sehingga bertahan setelah aplikasi
/// ditutup (PRD bagian 6 dan 7). Kelas ini tidak memuat data contoh: library
/// hanya berisi media yang benar-benar diimpor pengguna.
class SonoraState extends ChangeNotifier {
  SonoraState(
    this._engine, {
    required this.backend,
    this.library,
    this.disposeEngine = true,
    this.saveDebounce = const Duration(seconds: 2),
  }) {
    _bindEngine();
  }

  /// Jeda sebelum status pemutaran disimpan; nol berarti simpan segera.
  final Duration saveDebounce;

  final SonoraBackend backend;
  final MediaLibraryService? library;
  final bool disposeEngine;
  final AudioEngine _engine;

  /// Posisi pemutaran dipublikasikan terpisah agar UI pemutar dapat memutar
  /// ulang bagian kecil tanpa membangun ulang seluruh aplikasi.
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _saveTimer;
  bool _disposed = false;

  int _tab = 0;
  String? _selectedId;
  String? _loadedId;
  Duration _pendingRestorePosition = Duration.zero;
  bool _playing = false;
  Duration? _duration;
  double _volume = .72;
  bool _shuffle = false;
  SonoraRepeat _repeat = SonoraRepeat.off;
  bool _reduceMotion = false;
  bool _cyanAccent = false;
  bool _ready = false;
  String _sort = 'Terbaru ditambahkan';
  String? _notice;
  ImportProgress? _importProgress;
  List<MediaItem> _songs = const [];
  List<MediaItem> _videos = const [];
  List<Playlist> _playlists = const [];
  List<String> _queue = const [];
  final Set<String> _favorites = {};
  List<String>? _shuffleOrder;

  // ---------------------------------------------------------------- getter

  int get tab => _tab;
  bool get ready => _ready;
  bool get isPlaying => _playing;
  double get volume => _volume;
  bool get shuffle => _shuffle;
  SonoraRepeat get repeat => _repeat;
  bool get reduceMotion => _reduceMotion;
  bool get cyanAccent => _cyanAccent;
  String get sort => _sort;
  String? get notice => _notice;
  ImportProgress? get importProgress => _importProgress;
  bool get importing => _importProgress != null;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<MediaItem> get songs => List.unmodifiable(_songs);
  List<MediaItem> get videos => List.unmodifiable(_videos);
  List<String> get queueIds => List.unmodifiable(_queue);
  List<MediaItem> get queue =>
      _queue.map(itemById).whereType<MediaItem>().toList(growable: false);
  bool get hasSelection => selected != null;

  MediaItem? get selected => itemById(_selectedId);

  Duration get position {
    final value = positionNotifier.value;
    final total = duration;
    if (total == null) return value;
    return value > total ? total : value;
  }

  /// Durasi trek aktif; memakai metadata library bila pemutar belum melapor.
  Duration? get duration {
    final reported = _duration;
    if (reported != null && reported > Duration.zero) return reported;
    final item = selected;
    if (item == null || item.duration <= 0) return null;
    return item.durationValue;
  }

  List<MediaItem> get recentlyPlayed {
    final played = _songs.where((item) => item.lastPlayedAt != null).toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
    return played;
  }

  List<MediaItem> get recentlyAdded => _songs;

  MediaItem? itemById(String? id) {
    if (id == null) return null;
    for (final item in _songs) {
      if (item.id == id) return item;
    }
    for (final item in _videos) {
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
    if (playlist == null) return const [];
    return playlist.trackIds
        .map(itemById)
        .whereType<MediaItem>()
        .toList(growable: false);
  }

  List<MediaItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return songs;
    return _songs
        .where(
          (song) => [
            song.title,
            song.artist,
            song.album,
          ].any((field) => field.toLowerCase().contains(normalized)),
        )
        .toList(growable: false);
  }

  /// Mengambil pesan sekali tampil lalu menghapusnya.
  String? takeNotice() {
    final value = _notice;
    _notice = null;
    return value;
  }

  // ------------------------------------------------------------------ init

  /// Memuat seluruh data tersimpan. Aman dipanggil sekali saat startup.
  Future<void> init() async {
    await _reloadLibrary();
    await _reloadPlaylists();
    await _reloadQueue();
    await restorePreferences();
    await _restorePlaybackState();
    _ready = true;
    _notify();
  }

  Future<void> restorePreferences() async {
    final settings = backend.settings;
    try {
      _cyanAccent = await settings.readBool(SettingsKeys.cyanAccent);
      _reduceMotion = await settings.readBool(SettingsKeys.reduceMotion);
      _shuffle = await settings.readBool(SettingsKeys.shuffle);
      final storedVolume = await settings.read(SettingsKeys.volume);
      final parsedVolume = double.tryParse(storedVolume ?? '');
      if (parsedVolume != null) _volume = parsedVolume.clamp(0, 1);
      final repeat = await settings.read(SettingsKeys.repeatMode);
      _repeat = SonoraRepeat.values.firstWhere(
        (value) => value.name == repeat,
        orElse: () => SonoraRepeat.off,
      );
      final favorites = await settings.read(SettingsKeys.favorites);
      if (favorites != null && favorites.isNotEmpty) {
        _favorites
          ..clear()
          ..addAll(favorites.split('|').where((value) => value.isNotEmpty));
      }
      _shuffleOrder = _shuffle ? _buildShuffleOrder() : null;
      _notify();
    } catch (error) {
      debugPrint('SONORA: preferensi tersimpan tidak dapat dibaca ($error)');
    }
  }

  Future<void> _restorePlaybackState() async {
    try {
      final row = await backend.playback.read();
      final mediaId = row.currentMediaId;
      if (mediaId == null) return;
      final item = itemById(mediaId);
      if (item == null || item.kind != MediaKind.audio) return;
      _selectedId = item.id;
      _duration = item.durationValue;
      _pendingRestorePosition = Duration(milliseconds: row.positionMs);
      positionNotifier.value = _pendingRestorePosition;
      // Pemulihan tidak memutar otomatis agar tidak mengejutkan pengguna.
      await _engine.publishNowPlaying(item);
    } catch (error) {
      debugPrint('SONORA: status pemutaran tidak dapat dipulihkan ($error)');
    }
  }

  // -------------------------------------------------------------- pemutaran

  void _bindEngine() {
    _subscriptions.add(
      _engine.positionStream.listen((position) {
        positionNotifier.value = position;
      }),
    );
    _subscriptions.add(
      _engine.durationStream.listen((duration) {
        _duration = duration;
        _notify();
      }),
    );
    _subscriptions.add(
      _engine.playingStream.listen((playing) {
        if (_playing == playing) return;
        _playing = playing;
        if (!playing) _scheduleSave();
        _notify();
      }),
    );
    _subscriptions.add(_engine.completedStream.listen((_) => _onCompleted()));
  }

  Future<void> _onCompleted() async {
    if (_repeat == SonoraRepeat.one) {
      await _engine.seek(Duration.zero);
      await _engine.play();
      return;
    }
    await next(fromCompletion: true);
  }

  /// Memutar media tertentu sebagai trek aktif.
  Future<void> playItem(MediaItem item) async {
    if (item.kind != MediaKind.audio) return;
    if (!item.available) {
      _notice =
          'Berkas “${item.title}” tidak ditemukan. Impor ulang atau hapus dari library.';
      _notify();
      return;
    }
    await _startTrack(item);
  }

  Future<void> _startTrack(
    MediaItem item, {
    Duration startAt = Duration.zero,
    bool autoplay = true,
  }) async {
    _selectedId = item.id;
    _duration = item.duration > 0 ? item.durationValue : null;
    _pendingRestorePosition = startAt;
    positionNotifier.value = startAt;
    _notify();
    try {
      await _engine.load(item.uri, initialPosition: startAt);
      _loadedId = item.id;
      await _engine.setVolume(_volume);
      await _engine.publishNowPlaying(item);
      if (autoplay) {
        await _engine.play();
        await _recordPlay(item);
      }
    } catch (error) {
      debugPrint('SONORA: gagal memutar ${item.uri} ($error)');
      _loadedId = null;
      _playing = false;
      _notice =
          'Berkas “${item.title}” tidak dapat diputar. Media ditandai tidak tersedia.';
      await backend.media.markUnavailable(item.id);
      await _reloadLibrary();
      _notify();
    }
  }

  Future<void> _recordPlay(MediaItem item) async {
    try {
      await backend.media.markPlayed(item.id);
      await _reloadLibrary();
    } catch (error) {
      debugPrint('SONORA: riwayat pemutaran gagal dicatat ($error)');
    }
    _scheduleSave();
  }

  Future<void> togglePlay() async {
    final item = selected;
    if (item == null) return;
    if (_playing) {
      await _engine.pause();
      await _savePlaybackState();
      return;
    }
    if (_loadedId != item.id) {
      await _startTrack(item, startAt: _pendingRestorePosition);
      return;
    }
    final total = duration;
    if (total != null &&
        total > Duration.zero &&
        positionNotifier.value >= total) {
      await _engine.seek(Duration.zero);
    }
    await _engine.play();
    await _recordPlay(item);
  }

  Future<void> seek(Duration position) async {
    final total = duration;
    var target = position < Duration.zero ? Duration.zero : position;
    if (total != null && target > total) target = total;
    positionNotifier.value = target;
    if (_loadedId != null) {
      await _engine.seek(target);
    }
    _scheduleSave();
  }

  /// Next/Previous mengikuti urutan antrean, lalu library, dengan aturan
  /// repeat `off` berhenti di ujung antrean dan `all` kembali ke awal.
  Future<void> next({bool fromCompletion = false}) async {
    final order = _playbackOrder;
    final current = selected;
    if (order.isEmpty || current == null) return;
    if (_repeat == SonoraRepeat.one) {
      await _engine.seek(Duration.zero);
      await _engine.play();
      return;
    }
    final index = order.indexWhere((item) => item.id == current.id);
    if (index == -1) {
      await _startTrack(order.first);
      return;
    }
    if (index + 1 < order.length) {
      await _startTrack(order[index + 1]);
      return;
    }
    if (_repeat == SonoraRepeat.all) {
      await _startTrack(order.first);
      return;
    }
    // Ujung antrean dengan repeat nonaktif: pemutaran berhenti pada item terakhir.
    await _engine.pause();
    await _engine.seek(Duration.zero);
    positionNotifier.value = Duration.zero;
    _playing = false;
    await _savePlaybackState();
    _notify();
  }

  Future<void> previous() async {
    final current = selected;
    if (current == null) return;
    if (positionNotifier.value > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    final order = _playbackOrder;
    if (order.isEmpty) return;
    final index = order.indexWhere((item) => item.id == current.id);
    if (index == -1) {
      await _startTrack(order.last);
      return;
    }
    if (index - 1 >= 0) {
      await _startTrack(order[index - 1]);
      return;
    }
    if (_repeat == SonoraRepeat.all) {
      await _startTrack(order.last);
      return;
    }
    await seek(Duration.zero);
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0, 1);
    await _engine.setVolume(_volume);
    _notify();
    _persist((settings) => settings.write(SettingsKeys.volume, '$_volume'));
  }

  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    _shuffleOrder = _shuffle ? _buildShuffleOrder() : null;
    _notify();
    _persist((settings) => settings.writeBool(SettingsKeys.shuffle, _shuffle));
  }

  Future<void> cycleRepeat() async {
    _repeat =
        SonoraRepeat.values[(_repeat.index + 1) % SonoraRepeat.values.length];
    _notify();
    _persist(
      (settings) => settings.write(SettingsKeys.repeatMode, _repeat.name),
    );
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

  /// Menjaga urutan acak tetap stabil: item yang sudah ada mempertahankan
  /// posisinya, item baru ditambahkan di belakang, dan item yang hilang dibuang.
  void _syncShuffleOrder() {
    if (!_shuffle) {
      _shuffleOrder = null;
      return;
    }
    final existing = _shuffleOrder;
    if (existing == null) {
      _shuffleOrder = _buildShuffleOrder();
      return;
    }
    final ids = [
      for (final item in (queue.isNotEmpty ? queue : songs)) item.id,
    ];
    final kept = [
      for (final id in existing)
        if (ids.contains(id)) id,
    ];
    final added = [
      for (final id in ids)
        if (!kept.contains(id)) id,
    ];
    _shuffleOrder = [...kept, ...added];
  }

  List<String> _buildShuffleOrder() {
    final ids = <String>[
      for (final item in (queue.isNotEmpty ? queue : songs)) item.id,
    ];
    // Fisher-Yates dengan seed tetap agar urutan stabil antar rebuild.
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

  // ------------------------------------------------------------ preferensi

  Future<void> toggleFavorite(String id) async {
    if (!_favorites.add(id)) _favorites.remove(id);
    _notify();
    _persist(
      (settings) =>
          settings.write(SettingsKeys.favorites, _favorites.join('|')),
    );
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    _notify();
    _persist(
      (settings) => settings.writeBool(SettingsKeys.reduceMotion, value),
    );
  }

  Future<void> setAccent(bool cyan) async {
    _cyanAccent = cyan;
    _notify();
    _persist((settings) => settings.writeBool(SettingsKeys.cyanAccent, cyan));
  }

  void setSort(String value) {
    _sort = value;
    _notify();
  }

  void setTab(int value) {
    if (_tab == value) return;
    _tab = value;
    _notify();
  }

  void _persist(Future<void> Function(SettingsRepository settings) operation) {
    operation(backend.settings).catchError((Object error) {
      debugPrint('SONORA: preferensi gagal disimpan ($error)');
    });
  }

  void _scheduleSave() {
    if (saveDebounce == Duration.zero) {
      unawaited(_savePlaybackState());
      return;
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      unawaited(_savePlaybackState());
    });
  }

  /// Menyimpan status pemutaran segera tanpa menunggu penjadwalan.
  Future<void> flushPlaybackState() async {
    _saveTimer?.cancel();
    await _savePlaybackState();
  }

  Future<void> _savePlaybackState() async {
    if (_disposed) return;
    try {
      await backend.playback.save(
        currentMediaId: _selectedId,
        positionMs: positionNotifier.value.inMilliseconds,
        isPlaying: _playing,
        repeatMode: _repeat.name,
        shuffleEnabled: _shuffle,
        volume: _volume,
      );
    } catch (error) {
      debugPrint('SONORA: status pemutaran gagal disimpan ($error)');
    }
  }

  // ---------------------------------------------------------------- impor

  /// Membuka pemilih berkas lalu menyimpan hasilnya. Mengembalikan ringkasan
  /// impor atau `null` bila pemilih dibatalkan/gagal.
  Future<ImportReport?> importMedia(MediaKind kind) async {
    final service = library;
    if (service == null) {
      _notice = 'Impor media tidak tersedia pada sesi ini.';
      _notify();
      return null;
    }
    _notice = null;
    _importProgress = const ImportProgress(processed: 0, total: 0);
    _notify();
    try {
      final report = await service.importFromPicker(
        kind == MediaKind.audio ? MediaType.audio : MediaType.video,
        onProgress: (progress) {
          _importProgress = progress;
          _notify();
        },
      );
      await _reloadLibrary();
      return report;
    } on MediaImportException catch (error) {
      _notice = error.message;
      return null;
    } catch (error) {
      debugPrint('SONORA: impor gagal ($error)');
      _notice = 'Impor tidak dapat diselesaikan. Coba lagi.';
      return null;
    } finally {
      _importProgress = null;
      _notify();
    }
  }

  /// Menghapus media dari library beserta salinan milik aplikasi.
  Future<void> removeFromLibrary(String id) async {
    try {
      final service = library;
      if (service != null) {
        await service.removeFromLibrary(id);
      } else {
        await backend.media.removeFromLibrary(id);
      }
      if (_selectedId == id) {
        await _engine.stop();
        _selectedId = null;
        _loadedId = null;
        _playing = false;
        positionNotifier.value = Duration.zero;
      }
      await _reloadLibrary();
      await _reloadPlaylists();
      await _reloadQueue();
    } catch (error) {
      debugPrint('SONORA: media gagal dihapus ($error)');
      _notice = 'Media tidak dapat dihapus. Coba lagi.';
      _notify();
    }
  }

  /// Menjeda musik saat video diputar agar tidak ada dua sumber audio aktif
  /// (PRD bagian 8.8).
  Future<void> pausePlayback() async {
    if (!_playing) return;
    await _engine.pause();
    await _savePlaybackState();
  }

  /// Membersihkan media yang berkasnya sudah tidak dapat diakses.
  Future<int> removeUnavailableMedia() async {
    try {
      final removed = await backend.media.removeUnavailable();
      await _reloadLibrary();
      await _reloadPlaylists();
      await _reloadQueue();
      return removed;
    } catch (error) {
      debugPrint('SONORA: media tidak tersedia gagal dibersihkan ($error)');
      _notice = 'Media tidak tersedia tidak dapat dibersihkan.';
      _notify();
      return 0;
    }
  }

  Future<StorageSummary> storageSummary() async {
    var bytes = 0;
    final service = library;
    if (service != null) {
      bytes = await service.storage.totalBytes();
    }
    return StorageSummary(
      audioCount: _songs.length,
      videoCount: _videos.length,
      bytes: bytes,
    );
  }

  // -------------------------------------------------------------- playlist

  Future<String?> createPlaylist(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Nama playlist tidak boleh kosong.';
    if (_playlists.any(
      (playlist) => playlist.name.toLowerCase() == normalized.toLowerCase(),
    )) {
      return 'Nama playlist sudah digunakan.';
    }
    try {
      await backend.playlists.create(normalized);
      await _reloadPlaylists();
      return null;
    } on SonoraDataException catch (error) {
      return error.message;
    } catch (error) {
      debugPrint('SONORA: playlist gagal dibuat ($error)');
      return 'Playlist tidak dapat dibuat. Coba lagi.';
    }
  }

  Future<String?> renamePlaylist(String id, String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Nama playlist tidak boleh kosong.';
    if (_playlists.any(
      (playlist) =>
          playlist.id != id &&
          playlist.name.toLowerCase() == normalized.toLowerCase(),
    )) {
      return 'Nama playlist sudah digunakan.';
    }
    try {
      await backend.playlists.rename(id, normalized);
      await _reloadPlaylists();
      return null;
    } on SonoraDataException catch (error) {
      return error.message;
    } catch (error) {
      debugPrint('SONORA: playlist gagal diubah ($error)');
      return 'Nama playlist tidak dapat diubah. Coba lagi.';
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await backend.playlists.delete(id);
      await _reloadPlaylists();
    } catch (error) {
      debugPrint('SONORA: playlist gagal dihapus ($error)');
      _notice = 'Playlist tidak dapat dihapus. Coba lagi.';
      _notify();
    }
  }

  Future<void> addToPlaylist(String playlistId, String songId) async {
    try {
      await backend.playlists.addTrack(playlistId, songId);
      await _reloadPlaylists();
    } on SonoraDataException catch (error) {
      _notice = error.message;
      _notify();
    } catch (error) {
      debugPrint('SONORA: lagu gagal ditambahkan ($error)');
      _notice = 'Lagu tidak dapat ditambahkan ke playlist.';
      _notify();
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String songId) async {
    try {
      await backend.playlists.removeTrack(playlistId, songId);
      await _reloadPlaylists();
    } catch (error) {
      debugPrint('SONORA: lagu gagal dihapus dari playlist ($error)');
      _notice = 'Lagu tidak dapat dihapus dari playlist.';
      _notify();
    }
  }

  Future<void> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await backend.playlists.reorder(playlistId, oldIndex, newIndex);
      await _reloadPlaylists();
    } catch (error) {
      debugPrint('SONORA: urutan playlist gagal diubah ($error)');
      _notice = 'Urutan lagu tidak dapat diubah.';
      _notify();
    }
  }

  // ---------------------------------------------------------------- antrean

  Future<void> enqueue(String id) async {
    try {
      await backend.queue.enqueue(id, sourceType: 'library');
      await _reloadQueue();
      _notice = 'Ditambahkan ke antrean.';
      _notify();
    } on SonoraDataException catch (error) {
      _notice = error.message;
      _notify();
    } catch (error) {
      debugPrint('SONORA: gagal menambah antrean ($error)');
      _notice = 'Lagu tidak dapat ditambahkan ke antrean.';
      _notify();
    }
  }

  Future<void> removeFromQueueAt(int index) async {
    try {
      await backend.queue.removeAt(index);
    } catch (error) {
      debugPrint('SONORA: gagal menghapus item antrean ($error)');
    }
    await _reloadQueue();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      await backend.queue.reorder(oldIndex, newIndex);
    } catch (error) {
      debugPrint('SONORA: gagal mengubah urutan antrean ($error)');
    }
    await _reloadQueue();
  }

  Future<void> clearQueue() async {
    try {
      await backend.queue.clear();
    } catch (error) {
      debugPrint('SONORA: gagal mengosongkan antrean ($error)');
    }
    await _reloadQueue();
  }

  /// Mengganti antrean dengan sekumpulan media lalu memutar item pertama.
  Future<void> playCollection(
    List<MediaItem> items, {
    bool shuffled = false,
  }) async {
    if (items.isEmpty) return;
    try {
      await backend.queue.clear();
      for (final item in items) {
        await backend.queue.enqueue(item.id, sourceType: 'playlist');
      }
    } catch (error) {
      debugPrint('SONORA: gagal menyiapkan antrean playlist ($error)');
    }
    await _reloadQueue();
    final order = <MediaItem>[...items];
    if (shuffled && order.length > 1) {
      if (!_shuffle) await toggleShuffle();
      final ids = _shuffleOrder ?? _buildShuffleOrder();
      final byId = {for (final item in order) item.id: item};
      order
        ..clear()
        ..addAll(ids.map((id) => byId[id]).whereType<MediaItem>());
      for (final item in items) {
        if (!order.any((candidate) => candidate.id == item.id)) order.add(item);
      }
    }
    await _startTrack(order.first);
  }

  // ------------------------------------------------------------ pemuatan DB

  Future<void> _reloadLibrary() async {
    try {
      final rows = await backend.media.all();
      _songs = [
        for (final row in rows)
          if (row.mediaType == MediaType.audio.value) _toItem(row),
      ];
      _videos = [
        for (final row in rows)
          if (row.mediaType == MediaType.video.value) _toItem(row),
      ];
      _syncShuffleOrder();
      _notify();
    } catch (error) {
      debugPrint('SONORA: library gagal dibaca ($error)');
      _notice = 'Library tidak dapat dibaca dari penyimpanan lokal.';
    }
  }

  Future<void> _reloadPlaylists() async {
    try {
      final summaries = await backend.playlists.summaries();
      final playlists = <Playlist>[];
      for (final summary in summaries) {
        final tracks = await backend.playlists.tracks(summary.playlist.id);
        playlists.add(
          Playlist(
            id: summary.playlist.id,
            name: summary.playlist.name,
            trackIds: [for (final track in tracks) track.id],
          ),
        );
      }
      _playlists = playlists;
      _notify();
    } catch (error) {
      debugPrint('SONORA: playlist gagal dibaca ($error)');
      _notice = 'Playlist tidak dapat dibaca dari penyimpanan lokal.';
    }
  }

  Future<void> _reloadQueue() async {
    try {
      final rows = await backend.queue.items();
      _queue = [for (final row in rows) row.id];
      _syncShuffleOrder();
      _notify();
    } catch (error) {
      debugPrint('SONORA: antrean gagal dibaca ($error)');
      _notice = 'Antrean tidak dapat dibaca dari penyimpanan lokal.';
    }
  }

  MediaItem _toItem(MediaRow row) => MediaItem(
    id: row.id,
    title: row.title,
    artist: row.artist ?? 'Artis tidak diketahui',
    album: row.album ?? 'Album tidak diketahui',
    duration: row.durationMs == null ? 0 : (row.durationMs! / 1000).round(),
    uri: row.uri,
    artworkPath: row.artworkPath,
    kind: row.mediaType == MediaType.video.value
        ? MediaKind.video
        : MediaKind.audio,
    fileSizeBytes: row.fileSizeBytes ?? 0,
    playCount: row.playCount,
    lastPlayedAt: row.lastPlayedAt,
    available: row.availability == 'available',
  );

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Simpan status terakhir sebelum state dihentikan.
    unawaited(_savePlaybackState());
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    positionNotifier.dispose();
    if (disposeEngine) unawaited(_engine.dispose());
    super.dispose();
  }
}

/// Menyediakan [SonoraState] ke seluruh pohon widget.
class SonoraScope extends InheritedNotifier<SonoraState> {
  const SonoraScope({
    super.key,
    required SonoraState state,
    required super.child,
  }) : super(notifier: state);

  static SonoraState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SonoraScope>();
    assert(scope != null, 'SonoraScope tidak ditemukan.');
    return scope!.notifier!;
  }
}
