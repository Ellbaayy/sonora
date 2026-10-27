import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// `media_items` — record media lokal yang diimpor pengguna (PRD bagian 7).
@DataClassName('MediaRow')
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get uri => text()();
  TextColumn get fileName => text()();
  TextColumn get mediaType => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get artworkPath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();
  IntColumn get dateAdded => integer()();
  IntColumn get lastPlayedAt => integer().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  TextColumn get availability =>
      text().withDefault(const Constant('available'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CONSTRAINT media_items_uri_unique UNIQUE (uri)',
    "CONSTRAINT media_items_media_type_check "
        "CHECK (media_type IN ('audio', 'video'))",
    "CONSTRAINT media_items_availability_check "
        "CHECK (availability IN ('available', 'unavailable'))",
    'CONSTRAINT media_items_play_count_check CHECK (play_count >= 0)',
  ];
}

/// `playlists` — playlist lokal.
@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get artworkPath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CONSTRAINT playlists_name_not_blank CHECK (length(trim(name)) > 0)",
  ];
}

/// `playlist_items` — urutan track di dalam playlist.
/// Keputusan produk: satu lagu hanya boleh muncul sekali per playlist.
@DataClassName('PlaylistItemRow')
class PlaylistItems extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CONSTRAINT playlist_items_unique UNIQUE (playlist_id, media_id)',
    'CONSTRAINT playlist_items_position_check CHECK (position >= 0)',
  ];
}

/// `playback_state` — satu baris (id = 1) berisi konteks pemutaran terakhir.
@DataClassName('PlaybackStateRow')
class PlaybackStates extends Table {
  IntColumn get id => integer()();
  TextColumn get currentMediaId => text().nullable()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  BoolColumn get isPlaying => boolean().withDefault(const Constant(false))();
  TextColumn get repeatMode => text().withDefault(const Constant('off'))();
  BoolColumn get shuffleEnabled =>
      boolean().withDefault(const Constant(false))();
  RealColumn get volume => real().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CONSTRAINT playback_state_single_row CHECK (id = 1)',
    "CONSTRAINT playback_state_repeat_check "
        "CHECK (repeat_mode IN ('off', 'one', 'all'))",
    'CONSTRAINT playback_state_position_check CHECK (position_ms >= 0)',
    'CONSTRAINT playback_state_volume_check CHECK (volume >= 0 AND volume <= 1)',
  ];
}

/// `queue_items` — antrean persisten beserta sumbernya.
@DataClassName('QueueRow')
class QueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get sourceType => text().nullable()();
  TextColumn get sourceId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CONSTRAINT queue_items_position_check CHECK (position >= 0)',
    "CONSTRAINT queue_items_source_check CHECK (source_type IS NULL OR "
        "source_type IN ('library', 'playlist'))",
  ];
}

/// `app_settings` — penyimpanan key-value preferensi.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get settingKey => text().named('setting_key')();
  TextColumn get settingValue => text().named('setting_value')();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

@DriftDatabase(
  tables: [
    MediaItems,
    Playlists,
    PlaylistItems,
    PlaybackStates,
    QueueItems,
    AppSettings,
  ],
)
class SonoraDatabase extends _$SonoraDatabase {
  SonoraDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async {
      await m.createAll();
      await into(playbackStates).insert(
        PlaybackStatesCompanion.insert(id: const Value(1), updatedAt: 0),
      );
    },
  );
}

/// Membuka database aplikasi di penyimpanan internal perangkat.
QueryExecutor openSonoraDatabase() => driftDatabase(name: 'sonora');
