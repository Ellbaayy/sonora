import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;
import 'package:just_audio/just_audio.dart' as ja;

import '../media/media_item.dart';
import 'audio_engine.dart';

/// Handler audio yang menjalankan pemutaran di background service Android.
///
/// Notifikasi media, kontrol headset, dan tombol pada layar kunci memanggil
/// handler ini; UI aplikasi memakai [AudioServiceEngine] yang meneruskan
/// perintah ke handler yang sama sehingga hanya ada satu sumber status.
class SonoraAudioHandler extends audio.BaseAudioHandler with audio.SeekHandler {
  SonoraAudioHandler() {
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      onError: (Object error) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: audio.AudioProcessingState.error,
            playing: false,
          ),
        );
      },
    );
    _player.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed && !_completed.isClosed) {
        _completed.add(null);
      }
    });
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final _completed = StreamController<void>.broadcast();

  /// Aksi antrean disediakan oleh lapisan state aplikasi agar urutan
  /// next/previous mengikuti aturan produk (antrean lebih dulu, lalu library).
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<void> get completedStream => _completed.stream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;

  Future<void> load(
    String uri, {
    Duration initialPosition = Duration.zero,
  }) async {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      await _player.setFilePath(uri);
    } else if (parsed.scheme == 'file') {
      await _player.setFilePath(parsed.toFilePath());
    } else if (parsed.scheme.isEmpty) {
      await _player.setFilePath(uri);
    } else {
      await _player.setAudioSource(ja.AudioSource.uri(parsed));
    }
    if (initialPosition > Duration.zero) {
      await _player.seek(initialPosition);
    }
  }

  @override
  Future<void> play() async {
    // `just_audio` menyelesaikan future `play()` saat pemutaran berhenti,
    // sehingga hasilnya tidak ditunggu di sini.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1));

  /// Memperbarui metadata pada notifikasi media sistem.
  Future<void> publish(MediaItem? item) async {
    if (item == null) {
      mediaItem.add(null);
      return;
    }
    final artPath = item.artworkPath;
    mediaItem.add(
      audio.MediaItem(
        id: item.id,
        title: item.title,
        artist: item.artist,
        album: item.album,
        duration: item.duration > 0 ? Duration(seconds: item.duration) : null,
        artUri: artPath == null ? null : Uri.file(artPath),
      ),
    );
  }

  Future<void> disposePlayer() async {
    await _completed.close();
    await _player.dispose();
  }

  audio.PlaybackState _transformEvent(ja.PlaybackEvent event) {
    return audio.PlaybackState(
      controls: [
        audio.MediaControl.skipToPrevious,
        if (_player.playing)
          audio.MediaControl.pause
        else
          audio.MediaControl.play,
        audio.MediaControl.skipToNext,
      ],
      systemActions: const {audio.MediaAction.seek, audio.MediaAction.stop},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ja.ProcessingState.idle => audio.AudioProcessingState.idle,
        ja.ProcessingState.loading => audio.AudioProcessingState.loading,
        ja.ProcessingState.buffering => audio.AudioProcessingState.buffering,
        ja.ProcessingState.ready => audio.AudioProcessingState.ready,
        ja.ProcessingState.completed => audio.AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

/// [AudioEngine] yang memakai [SonoraAudioHandler].
class AudioServiceEngine implements AudioEngine {
  AudioServiceEngine(this.handler);

  final SonoraAudioHandler handler;

  @override
  Stream<Duration> get positionStream => handler.positionStream;

  @override
  Stream<Duration?> get durationStream => handler.durationStream;

  @override
  Stream<bool> get playingStream => handler.playingStream;

  @override
  Stream<void> get completedStream => handler.completedStream;

  @override
  Duration get position => handler.position;

  @override
  Duration? get duration => handler.duration;

  @override
  bool get playing => handler.playing;

  @override
  Future<void> load(String uri, {Duration initialPosition = Duration.zero}) =>
      handler.load(uri, initialPosition: initialPosition);

  @override
  Future<void> play() => handler.play();

  @override
  Future<void> pause() => handler.pause();

  @override
  Future<void> seek(Duration position) => handler.seek(position);

  @override
  Future<void> setVolume(double volume) => handler.setVolume(volume);

  @override
  Future<void> stop() => handler.stop();

  @override
  Future<void> publishNowPlaying(MediaItem? item) => handler.publish(item);

  @override
  Future<void> dispose() => handler.disposePlayer();
}
