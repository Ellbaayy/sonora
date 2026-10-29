import 'package:flutter/foundation.dart';

/// Jenis media yang dikelola aplikasi.
enum MediaKind { audio, video }

/// Gaya artwork prosedural yang dipakai bila berkas tidak menyertakan cover.
enum ArtworkStyle { waves, orbital, bloom, midnight, cinema, cassette }

/// Satu item media yang sudah tersimpan di library lokal.
///
/// [uri] menunjuk ke salinan berkas di penyimpanan aplikasi. Salinan dibuat saat
/// impor agar media tetap dapat diputar setelah pemilih berkas ditutup
/// (PRD bagian 6.1); berkas asli pengguna tidak pernah diubah atau dihapus.
@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.artworkPath,
    this.kind = MediaKind.audio,
    this.fileSizeBytes = 0,
    this.playCount = 0,
    this.lastPlayedAt,
    this.available = true,
  });

  final String id;
  final String title;
  final String artist;
  final String album;

  /// Durasi dalam detik; 0 berarti durasi belum diketahui.
  final int duration;
  final String uri;
  final String? artworkPath;
  final MediaKind kind;
  final int fileSizeBytes;
  final int playCount;
  final int? lastPlayedAt;
  final bool available;

  bool get hasArtwork => artworkPath != null && artworkPath!.isNotEmpty;

  /// Artwork prosedural deterministik: id yang sama selalu mendapat gaya yang
  /// sama sehingga tampilan tidak berubah antar rebuild.
  ArtworkStyle get style => artworkStyleFor(id);

  Duration get durationValue => Duration(seconds: duration);

  MediaItem copyWith({
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? artworkPath,
    int? playCount,
    int? lastPlayedAt,
    bool? available,
  }) => MediaItem(
    id: id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    duration: duration ?? this.duration,
    uri: uri,
    artworkPath: artworkPath ?? this.artworkPath,
    kind: kind,
    fileSizeBytes: fileSizeBytes,
    playCount: playCount ?? this.playCount,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    available: available ?? this.available,
  );
}

ArtworkStyle artworkStyleFor(String seed) {
  var hash = 7;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return ArtworkStyle.values[hash % ArtworkStyle.values.length];
}

String formatDuration(num seconds) {
  final value = seconds.toInt();
  if (value <= 0) return '0:00';
  final hours = value ~/ 3600;
  final minutes = (value % 3600) ~/ 60;
  final rest = (value % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$rest';
  }
  return '$minutes:$rest';
}
