import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/backend.dart';
import '../data/models.dart';
import 'media_metadata.dart';

/// Berkas yang dipilih pengguna melalui pemilih berkas sistem.
///
/// [path] tersedia bila platform memberi path lokal. Bila pemilih hanya
/// memberi URI (misalnya dokumen dari penyedia cloud), [openStream] dipakai
/// untuk menyalin isinya tanpa memuat seluruh berkas ke memori.
class PickedMedia {
  const PickedMedia({
    required this.fileName,
    required this.sizeBytes,
    this.path,
    this.openStream,
    this.mimeType,
  });

  final String fileName;
  final int sizeBytes;
  final String? path;
  final Stream<Uint8List> Function()? openStream;
  final String? mimeType;
}

/// Kemajuan impor yang dapat ditampilkan sebagai status di UI.
class ImportProgress {
  const ImportProgress({
    required this.processed,
    required this.total,
    this.fileName,
  });

  final int processed;
  final int total;
  final String? fileName;

  double get fraction => total == 0 ? 0 : processed / total;
}

/// Kesalahan impor dengan pesan yang aman ditampilkan ke pengguna.
class MediaImportException implements Exception {
  MediaImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pemilih berkas media. Android memakai Storage Access Framework sehingga
/// aplikasi tidak meminta akses seluruh penyimpanan (PRD bagian 10).
abstract class MediaPicker {
  Future<List<PickedMedia>> pick(MediaType type);
}

class FilePickerMediaPicker implements MediaPicker {
  static const audioExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
  ];
  static const videoExtensions = ['mp4', 'm4v', 'mkv', 'webm', '3gp'];

  @override
  Future<List<PickedMedia>> pick(MediaType type) async {
    List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        dialogTitle: type == MediaType.audio
            ? 'Pilih berkas musik'
            : 'Pilih berkas video',
        type: FileType.custom,
        allowedExtensions: type == MediaType.audio
            ? audioExtensions
            : videoExtensions,
      );
    } catch (error) {
      throw MediaImportException(
        'Pemilih berkas tidak dapat dibuka. Coba lagi dari layar ini.',
      );
    }
    if (files.isEmpty) return const [];
    final picked = <PickedMedia>[];
    for (final file in files) {
      final path = file.path;
      final size = file.lengthSync() ?? await file.length() ?? 0;
      picked.add(
        PickedMedia(
          fileName: file.name,
          sizeBytes: size,
          path: path,
          openStream: path == null ? file.readAsByteStream : null,
          mimeType: null,
        ),
      );
    }
    return picked;
  }
}

/// Penyimpanan media milik aplikasi.
///
/// Berkas disalin ke direktori aplikasi saat impor agar tetap dapat diputar
/// setelah pemilih berkas ditutup dan setelah perangkat dimulai ulang. Berkas
/// asli pengguna tidak pernah dipindahkan atau dihapus.
class MediaStorage {
  MediaStorage({required this.mediaDir, required this.artworkDir});

  final Directory mediaDir;
  final Directory artworkDir;

  static Future<MediaStorage> open() async {
    final base = await getApplicationSupportDirectory();
    return MediaStorage.at(Directory(p.join(base.path, 'media')));
  }

  /// Membuat penyimpanan di [root] (dipakai juga oleh pengujian).
  static Future<MediaStorage> at(Directory root) async {
    final media = Directory(p.join(root.path, 'media'));
    final artwork = Directory(p.join(root.path, 'artwork'));
    // Dibuat sinkron agar penyiapan penyimpanan selesai sebelum UI pertama.
    media.createSync(recursive: true);
    artwork.createSync(recursive: true);
    return MediaStorage(mediaDir: media, artworkDir: artwork);
  }

  Future<String> copyIn(PickedMedia picked) async {
    final extension = p.extension(picked.fileName).toLowerCase();
    final target = File(
      p.join(mediaDir.path, '${const Uuid().v4()}$extension'),
    );
    try {
      final sourcePath = picked.path;
      if (sourcePath != null && sourcePath.isNotEmpty) {
        await File(sourcePath).copy(target.path);
      } else if (picked.openStream != null) {
        final sink = target.openWrite();
        try {
          await sink.addStream(picked.openStream!());
        } finally {
          await sink.close();
        }
      } else {
        throw MediaImportException(
          'Berkas “${picked.fileName}” tidak dapat dibaca dari penyedia '
          'dokumen. Coba salin berkas ke penyimpanan perangkat lebih dulu.',
        );
      }
    } on FileSystemException {
      throw MediaImportException(
        'Berkas “${picked.fileName}” tidak dapat dibaca. Periksa izin akses '
        'berkas lalu coba lagi.',
      );
    }
    return target.path;
  }

  Future<String?> saveArtwork(Uint8List bytes, String? mimeType) async {
    if (bytes.isEmpty) return null;
    final extension = switch (mimeType?.toLowerCase()) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
    final file = File(
      p.join(artworkDir.path, '${const Uuid().v4()}$extension'),
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Berkas mungkin sudah hilang; tidak perlu menggagalkan alur pengguna.
    }
  }

  /// Ukuran total salinan media milik aplikasi dalam byte.
  Future<int> totalBytes() async {
    var total = 0;
    if (!await mediaDir.exists()) return 0;
    await for (final entity in mediaDir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}

/// Layanan impor dan penghapusan media di library lokal.
class MediaLibraryService {
  MediaLibraryService({
    required this.backend,
    required this.picker,
    required this.storage,
    this.reader = const MediaMetadataReader(),
  });

  final SonoraBackend backend;
  final MediaPicker picker;
  final MediaStorage storage;
  final MediaMetadataReader reader;

  /// Membuka pemilih berkas, menyalin berkas terpilih, membaca metadata, lalu
  /// menyimpannya ke database. Ringkasan hasil dipakai UI untuk menampilkan
  /// jumlah berhasil, duplikat, dan ditolak (PRD bagian 8.4).
  Future<ImportReport> importFromPicker(
    MediaType type, {
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final picked = await picker.pick(type);
    if (picked.isEmpty) return const ImportReport([]);
    final drafts = <MediaDraft>[];
    for (var index = 0; index < picked.length; index++) {
      final file = picked[index];
      onProgress?.call(
        ImportProgress(
          processed: index,
          total: picked.length,
          fileName: file.fileName,
        ),
      );
      final copyPath = await storage.copyIn(file);
      final metadata = await reader.read(copyPath);
      String? artworkPath;
      final artworkBytes = metadata.artworkBytes;
      if (artworkBytes != null) {
        artworkPath = await storage.saveArtwork(
          artworkBytes,
          metadata.artworkMimeType,
        );
      }
      drafts.add(
        MediaDraft(
          uri: copyPath,
          fileName: file.fileName,
          mediaType: type,
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album,
          durationMs: metadata.durationMs,
          mimeType: file.mimeType,
          fileSizeBytes: file.sizeBytes,
          artworkPath: artworkPath,
        ),
      );
    }
    final report = await backend.media.importDrafts(drafts);
    for (final outcome in report.outcomes) {
      if (outcome.status == ImportStatus.imported) continue;
      // Salinan untuk berkas duplikat/ditolak tidak dipakai lagi.
      await storage.deleteQuietly(outcome.draft.uri);
      await storage.deleteQuietly(outcome.draft.artworkPath);
    }
    onProgress?.call(
      ImportProgress(processed: picked.length, total: picked.length),
    );
    return report;
  }

  /// Menghapus record media beserta salinan milik aplikasi. Berkas asli
  /// pengguna tidak disentuh (PRD bagian 6.1).
  Future<void> removeFromLibrary(String mediaId) async {
    final row = await backend.media.byId(mediaId);
    if (row == null) return;
    await backend.media.removeFromLibrary(mediaId);
    await storage.deleteQuietly(row.uri);
    await storage.deleteQuietly(row.artworkPath);
  }
}
