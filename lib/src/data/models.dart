import 'database.dart';

/// Tipe media yang didukung lapisan data SONORA.
enum MediaType {
  audio('audio'),
  video('video');

  const MediaType(this.value);
  final String value;

  static MediaType? fromValue(String value) {
    for (final type in MediaType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Data calon media yang datang dari pemilih berkas sebelum divalidasi.
///
/// Lapisan data tidak mempercayai ekstensi saja: [mediaType] dan [mimeType]
/// diperiksa ulang saat impor (PRD bagian 6.1).
class MediaDraft {
  const MediaDraft({
    required this.uri,
    required this.fileName,
    required this.mediaType,
    this.title,
    this.artist,
    this.album,
    this.durationMs,
    this.mimeType,
    this.fileSizeBytes,
    this.artworkPath,
  });

  final String uri;
  final String fileName;
  final MediaType mediaType;
  final String? title;
  final String? artist;
  final String? album;
  final int? durationMs;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? artworkPath;
}

/// Hasil satu calon media saat impor.
enum ImportStatus { imported, duplicate, rejected }

class ImportOutcome {
  const ImportOutcome(this.draft, this.status, {this.reason});

  final MediaDraft draft;
  final ImportStatus status;
  final String? reason;

  String get fileName => draft.fileName;
}

/// Ringkasan impor yang siap ditampilkan ke pengguna (PRD bagian 8.4).
class ImportReport {
  const ImportReport(this.outcomes);

  final List<ImportOutcome> outcomes;

  int get importedCount =>
      outcomes.where((o) => o.status == ImportStatus.imported).length;
  int get duplicateCount =>
      outcomes.where((o) => o.status == ImportStatus.duplicate).length;
  int get rejectedCount =>
      outcomes.where((o) => o.status == ImportStatus.rejected).length;
  bool get isEmpty => outcomes.isEmpty;

  List<ImportOutcome> get rejected => outcomes
      .where((o) => o.status == ImportStatus.rejected)
      .toList(growable: false);
}

/// Playlist beserta jumlah track, untuk daftar di layar Playlist.
class PlaylistSummary {
  const PlaylistSummary({required this.playlist, required this.trackCount});

  final PlaylistRow playlist;
  final int trackCount;
}

/// Kesalahan validasi yang pesannya aman ditampilkan ke pengguna.
class SonoraDataException implements Exception {
  SonoraDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
