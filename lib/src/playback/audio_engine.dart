import 'dart:async';

import '../media/media_item.dart';

/// Kontrak mesin pemutaran audio.
///
/// Aplikasi memakai implementasi berbasis `just_audio` + `audio_service` di
/// perangkat, sedangkan widget test memakai [FakeAudioEngine] sehingga tidak
/// membutuhkan plugin native.
abstract class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;

  /// Selesai memutar satu berkas (bukan karena dijeda pengguna).
  Stream<void> get completedStream;

  Duration get position;
  Duration? get duration;
  bool get playing;

  /// Memuat berkas dan memindahkan posisi ke [initialPosition].
  Future<void> load(String uri, {Duration initialPosition = Duration.zero});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> stop();

  /// Memperbarui metadata pada notifikasi media sistem.
  Future<void> publishNowPlaying(MediaItem? item);

  Future<void> dispose();
}

/// Mesin audio tiruan untuk pengujian.
///
/// Posisi maju mengikuti waktu nyata selama status memutar, sehingga widget
/// test dapat memverifikasi kontrol play/pause/seek tanpa plugin native.
class FakeAudioEngine implements AudioEngine {
  FakeAudioEngine({Duration? duration, this.autoAdvance = true})
    : _duration = duration ?? const Duration(seconds: 180);

  final Duration _duration;

  /// Bila `false`, posisi tidak maju sendiri dan tidak ada timer berjalan;
  /// dipakai widget test agar tidak ada timer tertinggal.
  final bool autoAdvance;
  final _position = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();
  Timer? _ticker;
  Duration _current = Duration.zero;
  bool _isPlaying = false;
  double _volume = 1;
  bool _disposed = false;
  String? lastLoadedUri;
  MediaItem? publishedItem;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Duration get position => _current;

  @override
  Duration? get duration => _duration;

  @override
  bool get playing => _isPlaying;

  @override
  Future<void> load(
    String uri, {
    Duration initialPosition = Duration.zero,
  }) async {
    lastLoadedUri = uri;
    _current = initialPosition;
    _position.add(_current);
    _durationController.add(_duration);
  }

  @override
  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _playing.add(true);
    if (!autoAdvance) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _current += const Duration(milliseconds: 200);
      if (_current >= _duration) {
        _current = _duration;
        _position.add(_current);
        pause();
        _completed.add(null);
        return;
      }
      _position.add(_current);
    });
  }

  /// Menandai pemutaran selesai (dipakai pengujian logika lanjut otomatis).
  void emitCompleted() {
    _current = _duration;
    _position.add(_current);
    _completed.add(null);
  }

  /// Memindahkan posisi tanpa menunggu waktu nyata.
  void advance(Duration delta) {
    _current += delta;
    _position.add(_current);
  }

  @override
  Future<void> pause() async {
    _ticker?.cancel();
    _ticker = null;
    if (!_isPlaying) return;
    _isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _current = position < Duration.zero
        ? Duration.zero
        : (position > _duration ? _duration : position);
    _position.add(_current);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0, 1);
  }

  double get volume => _volume;

  @override
  Future<void> stop() async {
    await pause();
    _current = Duration.zero;
    _position.add(_current);
  }

  @override
  Future<void> publishNowPlaying(MediaItem? item) async {
    publishedItem = item;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ticker?.cancel();
    await _position.close();
    await _durationController.close();
    await _playing.close();
    await _completed.close();
  }
}
