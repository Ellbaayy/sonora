import 'database.dart';
import 'repositories.dart';

/// Titik masuk lapisan data SONORA: satu database dan seluruh repository.
///
/// Aplikasi offline ini tidak memakai server; "backend" berarti lapisan
/// layanan dan penyimpanan lokal (PRD bagian 5 dan 11).
class SonoraBackend {
  SonoraBackend(this.database)
    : media = MediaRepository(database),
      playlists = PlaylistRepository(database),
      queue = QueueRepository(database),
      playback = PlaybackStateRepository(database),
      settings = SettingsRepository(database);

  /// Membuka database aplikasi di penyimpanan internal perangkat.
  ///
  /// Query pembuka dijalankan agar kegagalan (berkas rusak, migrasi gagal)
  /// muncul di sini dan bisa ditangani pemanggil, bukan saat UI pertama dibaca.
  static Future<SonoraBackend> open() async {
    final backend = SonoraBackend(SonoraDatabase(openSonoraDatabase()));
    await backend.database.customSelect('SELECT 1').getSingle();
    return backend;
  }

  final SonoraDatabase database;
  final MediaRepository media;
  final PlaylistRepository playlists;
  final QueueRepository queue;
  final PlaybackStateRepository playback;
  final SettingsRepository settings;

  Future<void> close() => database.close();
}
