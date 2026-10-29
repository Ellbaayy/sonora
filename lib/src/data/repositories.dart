import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'models.dart';

/// Repository media lokal: impor, pencarian, penandaan, dan penghapusan record.
class MediaRepository {
  MediaRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? (() => const Uuid().v4());

  final SonoraDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg',
    '.opus',
  };
  static const _videoExtensions = {'.mp4', '.m4v', '.mkv', '.webm', '.3gp'};

  /// Mengimpor sekumpulan calon media dan mengembalikan ringkasan per berkas.
  ///
  /// Duplikat dikenali dari URI yang sama atau kombinasi nama berkas dan ukuran
  /// yang sama, sehingga pemilihan ulang berkas yang sama tidak menambah baris.
  Future<ImportReport> importDrafts(List<MediaDraft> drafts) async {
    final outcomes = <ImportOutcome>[];
    for (final draft in drafts) {
      final rejection = _validate(draft);
      if (rejection != null) {
        outcomes.add(
          ImportOutcome(draft, ImportStatus.rejected, reason: rejection),
        );
        continue;
      }
      final duplicate = await _findDuplicate(draft);
      if (duplicate != null) {
        outcomes.add(
          ImportOutcome(
            draft,
            ImportStatus.duplicate,
            reason: 'Media sudah ada di library.',
          ),
        );
        continue;
      }
      await _db
          .into(_db.mediaItems)
          .insert(
            MediaItemsCompanion.insert(
              id: _newId(),
              uri: draft.uri.trim(),
              fileName: draft.fileName.trim(),
              mediaType: draft.mediaType.value,
              title: _titleFor(draft),
              artist: Value(_emptyToNull(draft.artist)),
              album: Value(_emptyToNull(draft.album)),
              durationMs: Value(draft.durationMs),
              artworkPath: Value(_emptyToNull(draft.artworkPath)),
              mimeType: Value(_emptyToNull(draft.mimeType)),
              fileSizeBytes: Value(draft.fileSizeBytes),
              dateAdded: _clock().millisecondsSinceEpoch,
            ),
          );
      outcomes.add(ImportOutcome(draft, ImportStatus.imported));
    }
    return ImportReport(List.unmodifiable(outcomes));
  }

  Future<List<MediaRow>> all({MediaType? type}) async {
    final query = _db.select(_db.mediaItems);
    if (type != null) {
      query.where((t) => t.mediaType.equals(type.value));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.dateAdded)]);
    return query.get();
  }

  /// Pencarian lokal tanpa internet: judul, artis, album, dan nama berkas.
  Future<List<MediaRow>> search(String query, {MediaType? type}) async {
    final normalized = query.trim().toLowerCase();
    final statement = _db.select(_db.mediaItems);
    if (type != null) {
      statement.where((t) => t.mediaType.equals(type.value));
    }
    if (normalized.isNotEmpty) {
      final pattern = '%${_escapeLike(normalized)}%';
      statement.where(
        (t) =>
            t.title.lower().like(pattern) |
            t.fileName.lower().like(pattern) |
            t.artist.lower().like(pattern) |
            t.album.lower().like(pattern),
      );
    }
    statement.orderBy([(t) => OrderingTerm.desc(t.dateAdded)]);
    return statement.get();
  }

  Future<MediaRow?> byId(String id) => (_db.select(
    _db.mediaItems,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Menandai media yang berkasnya tidak lagi dapat diakses.
  Future<void> markUnavailable(String id) async {
    await (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
      const MediaItemsCompanion(availability: Value('unavailable')),
    );
  }

  /// Mencatat pemutaran untuk riwayat "Recently Played".
  Future<void> markPlayed(String id) async {
    final row = await byId(id);
    if (row == null) return;
    await (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        lastPlayedAt: Value(_clock().millisecondsSinceEpoch),
        playCount: Value(row.playCount + 1),
      ),
    );
  }

  /// Menghapus record aplikasi saja; berkas asli tidak disentuh (PRD 6.1).
  Future<int> removeFromLibrary(String id) =>
      (_db.delete(_db.mediaItems)..where((t) => t.id.equals(id))).go();

  Future<int> removeUnavailable() => (_db.delete(
    _db.mediaItems,
  )..where((t) => t.availability.equals('unavailable'))).go();

  String? _validate(MediaDraft draft) {
    if (draft.uri.trim().isEmpty) return 'URI media kosong.';
    if (draft.fileName.trim().isEmpty) return 'Nama berkas kosong.';
    final extension = p.extension(draft.fileName).toLowerCase();
    final allowed = draft.mediaType == MediaType.audio
        ? _audioExtensions
        : _videoExtensions;
    if (!allowed.contains(extension)) {
      final label = extension.isEmpty ? 'tanpa ekstensi' : extension;
      return 'Format $label tidak didukung untuk media '
          '${draft.mediaType.value}.';
    }
    final mime = draft.mimeType?.trim().toLowerCase();
    if (mime != null && mime.isNotEmpty) {
      final expectedPrefix = '${draft.mediaType.value}/';
      final looksLikeMedia =
          mime.startsWith('audio/') || mime.startsWith('video/');
      if (!looksLikeMedia || !mime.startsWith(expectedPrefix)) {
        return 'MIME type tidak sesuai dengan jenis media.';
      }
    }
    final duration = draft.durationMs;
    if (duration != null && duration < 0) return 'Durasi media tidak valid.';
    final size = draft.fileSizeBytes;
    if (size != null && size < 0) return 'Ukuran berkas tidak valid.';
    return null;
  }

  Future<MediaRow?> _findDuplicate(MediaDraft draft) async {
    final byUri = await (_db.select(
      _db.mediaItems,
    )..where((t) => t.uri.equals(draft.uri.trim()))).getSingleOrNull();
    if (byUri != null) return byUri;
    final size = draft.fileSizeBytes;
    if (size == null) return null;
    return (_db.select(_db.mediaItems)..where(
          (t) =>
              t.fileName.equals(draft.fileName.trim()) &
              t.fileSizeBytes.equals(size),
        ))
        .getSingleOrNull();
  }

  String _titleFor(MediaDraft draft) {
    final title = draft.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    final base = p.basenameWithoutExtension(draft.fileName.trim());
    return base.isEmpty ? draft.fileName.trim() : base;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String _escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}

/// Repository playlist dengan operasi transaksional.
class PlaylistRepository {
  PlaylistRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? (() => const Uuid().v4());

  final SonoraDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  static const maxNameLength = 80;

  Future<List<PlaylistSummary>> summaries() async {
    final playlists = await (_db.select(
      _db.playlists,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    final counts = await _db
        .customSelect(
          'SELECT playlist_id AS pid, COUNT(*) AS total '
          'FROM playlist_items GROUP BY playlist_id',
        )
        .get();
    final totals = {
      for (final row in counts) row.read<String>('pid'): row.read<int>('total'),
    };
    return [
      for (final playlist in playlists)
        PlaylistSummary(
          playlist: playlist,
          trackCount: totals[playlist.id] ?? 0,
        ),
    ];
  }

  Future<PlaylistRow?> byId(String id) => (_db.select(
    _db.playlists,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<PlaylistRow> create(String name, {String? description}) async {
    final normalized = _validatedName(name);
    final now = _clock().millisecondsSinceEpoch;
    final row = PlaylistsCompanion.insert(
      id: _newId(),
      name: normalized,
      description: Value(
        description?.trim().isEmpty ?? true ? null : description!.trim(),
      ),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.playlists).insert(row);
    return (await byId(row.id.value))!;
  }

  Future<void> rename(String id, String name) async {
    final normalized = _validatedName(name);
    final affected =
        await (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
          PlaylistsCompanion(
            name: Value(normalized),
            updatedAt: Value(_clock().millisecondsSinceEpoch),
          ),
        );
    if (affected == 0) {
      throw SonoraDataException('Playlist tidak ditemukan.');
    }
  }

  /// Menghapus playlist beserta isinya; media sumber tetap ada (PRD 6.4).
  Future<void> delete(String id) async {
    await (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addTrack(String playlistId, String mediaId) async {
    await _db.transaction(() async {
      final playlist = await byId(playlistId);
      if (playlist == null) {
        throw SonoraDataException('Playlist tidak ditemukan.');
      }
      final media = await (_db.select(
        _db.mediaItems,
      )..where((t) => t.id.equals(mediaId))).getSingleOrNull();
      if (media == null) {
        throw SonoraDataException('Media tidak ditemukan di library.');
      }
      final existing =
          await (_db.select(_db.playlistItems)..where(
                (t) =>
                    t.playlistId.equals(playlistId) & t.mediaId.equals(mediaId),
              ))
              .getSingleOrNull();
      if (existing != null) {
        throw SonoraDataException('Lagu sudah ada di playlist ini.');
      }
      final nextPosition = await _nextPosition(playlistId);
      await _db
          .into(_db.playlistItems)
          .insert(
            PlaylistItemsCompanion.insert(
              id: _newId(),
              playlistId: playlistId,
              mediaId: mediaId,
              position: nextPosition,
              addedAt: _clock().millisecondsSinceEpoch,
            ),
          );
      await _touch(playlistId);
    });
  }

  Future<void> removeTrack(String playlistId, String mediaId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.playlistItems)..where(
            (t) => t.playlistId.equals(playlistId) & t.mediaId.equals(mediaId),
          ))
          .go();
      await _renumber(playlistId);
      await _touch(playlistId);
    });
  }

  Future<void> reorder(String playlistId, int oldIndex, int newIndex) async {
    await _db.transaction(() async {
      final rows = await _orderedItems(playlistId);
      if (oldIndex < 0 || oldIndex >= rows.length) {
        throw SonoraDataException('Posisi track tidak valid.');
      }
      final bounded = newIndex.clamp(0, rows.length - 1);
      if (bounded == oldIndex) return;
      final moved = rows.removeAt(oldIndex);
      rows.insert(bounded, moved);
      await _writePositions(rows);
      await _touch(playlistId);
    });
  }

  Future<List<MediaRow>> tracks(String playlistId) async {
    final rows = await _orderedItems(playlistId);
    if (rows.isEmpty) return const [];
    final ids = rows.map((row) => row.mediaId).toList();
    final media = await (_db.select(
      _db.mediaItems,
    )..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final item in media) item.id: item};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<List<PlaylistItemRow>> _orderedItems(String playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<int> _nextPosition(String playlistId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(position), -1) AS max_position '
          'FROM playlist_items WHERE playlist_id = ?',
          variables: [Variable<String>(playlistId)],
        )
        .getSingle();
    return row.read<int>('max_position') + 1;
  }

  Future<void> _renumber(String playlistId) async {
    final rows = await _orderedItems(playlistId);
    await _writePositions(rows);
  }

  Future<void> _writePositions(List<PlaylistItemRow> rows) async {
    for (var index = 0; index < rows.length; index++) {
      if (rows[index].position == index) continue;
      await (_db.update(_db.playlistItems)
            ..where((t) => t.id.equals(rows[index].id)))
          .write(PlaylistItemsCompanion(position: Value(index)));
    }
  }

  Future<void> _touch(String playlistId) async {
    await (_db.update(
      _db.playlists,
    )..where((t) => t.id.equals(playlistId))).write(
      PlaylistsCompanion(updatedAt: Value(_clock().millisecondsSinceEpoch)),
    );
  }

  String _validatedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw SonoraDataException('Nama playlist tidak boleh kosong.');
    }
    if (trimmed.length > maxNameLength) {
      throw SonoraDataException(
        'Nama playlist maksimal $maxNameLength karakter.',
      );
    }
    return trimmed;
  }
}

/// Repository antrean persisten.
class QueueRepository {
  QueueRepository(this._db, {String Function()? idGenerator})
    : _newId = idGenerator ?? (() => const Uuid().v4());

  final SonoraDatabase _db;
  final String Function() _newId;

  Future<List<MediaRow>> items() async {
    final rows = await (_db.select(
      _db.queueItems,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    if (rows.isEmpty) return const [];
    final media = await (_db.select(
      _db.mediaItems,
    )..where((t) => t.id.isIn(rows.map((row) => row.mediaId).toList()))).get();
    final byId = {for (final item in media) item.id: item};
    return [
      for (final row in rows)
        if (byId[row.mediaId] != null) byId[row.mediaId]!,
    ];
  }

  /// Menambahkan media ke akhir antrean tanpa mengganti item aktif (PRD 6.3).
  Future<void> enqueue(
    String mediaId, {
    String? sourceType,
    String? sourceId,
  }) async {
    await _db.transaction(() async {
      final media = await (_db.select(
        _db.mediaItems,
      )..where((t) => t.id.equals(mediaId))).getSingleOrNull();
      if (media == null) {
        throw SonoraDataException('Media tidak ditemukan di library.');
      }
      if (sourceType != null &&
          sourceType != 'library' &&
          sourceType != 'playlist') {
        throw SonoraDataException('Sumber antrean tidak dikenal.');
      }
      final nextPosition = await _nextPosition();
      await _db
          .into(_db.queueItems)
          .insert(
            QueueItemsCompanion.insert(
              id: _newId(),
              mediaId: mediaId,
              position: nextPosition,
              sourceType: Value(sourceType),
              sourceId: Value(sourceId),
            ),
          );
    });
  }

  Future<void> removeAt(int position) async {
    await _db.transaction(() async {
      final rows = await _orderedItems();
      if (position < 0 || position >= rows.length) {
        throw SonoraDataException('Posisi antrean tidak valid.');
      }
      await (_db.delete(
        _db.queueItems,
      )..where((t) => t.id.equals(rows[position].id))).go();
      await _writePositions(rows..removeAt(position));
    });
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await _db.transaction(() async {
      final rows = await _orderedItems();
      if (oldIndex < 0 || oldIndex >= rows.length) {
        throw SonoraDataException('Posisi antrean tidak valid.');
      }
      final bounded = newIndex.clamp(0, rows.length - 1);
      if (bounded == oldIndex) return;
      final moved = rows.removeAt(oldIndex);
      rows.insert(bounded, moved);
      await _writePositions(rows);
    });
  }

  Future<void> clear() async {
    await _db.delete(_db.queueItems).go();
  }

  Future<List<QueueRow>> _orderedItems() => (_db.select(
    _db.queueItems,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

  Future<int> _nextPosition() async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(position), -1) AS max_position FROM queue_items',
        )
        .getSingle();
    return row.read<int>('max_position') + 1;
  }

  Future<void> _writePositions(List<QueueRow> rows) async {
    for (var index = 0; index < rows.length; index++) {
      if (rows[index].position == index) continue;
      await (_db.update(_db.queueItems)
            ..where((t) => t.id.equals(rows[index].id)))
          .write(QueueItemsCompanion(position: Value(index)));
    }
  }
}

/// Menyimpan dan memulihkan konteks pemutaran terakhir.
class PlaybackStateRepository {
  PlaybackStateRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SonoraDatabase _db;
  final DateTime Function() _clock;

  Future<PlaybackStateRow> read() async {
    final row = await (_db.select(
      _db.playbackStates,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row != null) return row;
    final now = _clock().millisecondsSinceEpoch;
    await _db
        .into(_db.playbackStates)
        .insert(
          PlaybackStatesCompanion.insert(id: const Value(1), updatedAt: now),
        );
    return (_db.select(
      _db.playbackStates,
    )..where((t) => t.id.equals(1))).getSingle();
  }

  Future<void> save({
    String? currentMediaId,
    int positionMs = 0,
    bool isPlaying = false,
    String repeatMode = 'off',
    bool shuffleEnabled = false,
    double volume = 1,
  }) async {
    if (positionMs < 0) {
      throw SonoraDataException('Posisi pemutaran tidak valid.');
    }
    if (!const {'off', 'one', 'all'}.contains(repeatMode)) {
      throw SonoraDataException('Mode repeat tidak dikenal.');
    }
    if (volume < 0 || volume > 1) {
      throw SonoraDataException('Volume harus di antara 0 dan 1.');
    }
    await _db
        .into(_db.playbackStates)
        .insertOnConflictUpdate(
          PlaybackStatesCompanion.insert(
            id: const Value(1),
            currentMediaId: Value(currentMediaId),
            positionMs: Value(positionMs),
            isPlaying: Value(isPlaying),
            repeatMode: Value(repeatMode),
            shuffleEnabled: Value(shuffleEnabled),
            volume: Value(volume),
            updatedAt: _clock().millisecondsSinceEpoch,
          ),
        );
  }
}

/// Preferensi aplikasi berbasis key-value.
class SettingsRepository {
  SettingsRepository(this._db);

  final SonoraDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).getSingleOrNull();
    return row?.settingValue;
  }

  /// Mengembalikan nilai bawaan bila key belum pernah disimpan.
  Future<bool> readBool(String key, {bool fallback = false}) async {
    final value = await read(key);
    if (value == null) return fallback;
    return value == 'true';
  }

  Future<void> write(String key, String value) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      throw SonoraDataException('Kunci pengaturan tidak boleh kosong.');
    }
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: trimmedKey,
            settingValue: value,
          ),
        );
  }

  Future<void> writeBool(String key, bool value) =>
      write(key, value ? 'true' : 'false');

  Future<void> remove(String key) => (_db.delete(
    _db.appSettings,
  )..where((t) => t.settingKey.equals(key))).go();
}

/// Kunci pengaturan yang dipakai aplikasi.
abstract final class SettingsKeys {
  static const cyanAccent = 'ui.cyan_accent';
  static const reduceMotion = 'ui.reduce_motion';
  static const repeatMode = 'playback.repeat_mode';
  static const shuffle = 'playback.shuffle';
  static const volume = 'playback.volume';
  static const favorites = 'library.favorites';
}
