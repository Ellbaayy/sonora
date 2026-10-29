import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// Metadata yang berhasil dibaca dari berkas media.
class ImportedMetadata {
  const ImportedMetadata({
    this.title,
    this.artist,
    this.album,
    this.durationMs,
    this.artworkBytes,
    this.artworkMimeType,
  });

  final String? title;
  final String? artist;
  final String? album;
  final int? durationMs;
  final Uint8List? artworkBytes;
  final String? artworkMimeType;

  bool get isEmpty =>
      title == null && artist == null && album == null && durationMs == null;
}

/// Pembaca metadata lokal (ID3, Vorbis, MP4 ilst, dan lainnya).
///
/// Berkas yang rusak atau formatnya tidak dikenal tidak menggagalkan impor:
/// pemanggil menerima [ImportedMetadata] kosong dan memakai nama berkas sebagai
/// judul (PRD bagian 6.6).
class MediaMetadataReader {
  const MediaMetadataReader();

  Future<ImportedMetadata> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return const ImportedMetadata();
    try {
      final metadata = readMetadata(file, getImage: true);
      final picture = metadata.pictures.isEmpty
          ? null
          : metadata.pictures.first;
      return ImportedMetadata(
        title: _clean(metadata.title),
        artist: _clean(metadata.artist),
        album: _clean(metadata.album),
        durationMs: metadata.duration?.inMilliseconds,
        artworkBytes: picture?.bytes,
        artworkMimeType: picture?.mimetype,
      );
    } catch (_) {
      // Format tanpa tag yang didukung atau berkas rusak: lanjutkan tanpa tag.
      return const ImportedMetadata();
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    // Beberapa tag berisi karakter NUL; bersihkan agar tidak muncul di UI.
    return trimmed.replaceAll('\u0000', '').trim();
  }
}
