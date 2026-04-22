import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/mood_entry.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'mood_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remoteId TEXT,
            emoji TEXT NOT NULL,
            reason TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'General',
            keywords TEXT,
            imageUrl TEXT,
            dateTime TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE moods ADD COLUMN remoteId TEXT");
          await db.execute(
            "ALTER TABLE moods ADD COLUMN category TEXT NOT NULL DEFAULT 'General'",
          );
          await db.execute("ALTER TABLE moods ADD COLUMN keywords TEXT");
          await db.execute("ALTER TABLE moods ADD COLUMN imageUrl TEXT");
        }
      },
    );
  }

  Future<int> insertEntry(MoodEntry entry) async {
    final db = await database;
    return await db.insert('moods', entry.toMap());
  }

  Future<List<MoodEntry>> getEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'moods',
      orderBy: 'dateTime DESC',
    );
    return maps.map((e) => MoodEntry.fromMap(e)).toList();
  }

  Future<MoodEntry?> getEntryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'moods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MoodEntry.fromMap(maps.first);
  }

  Future<int> updateEntry(MoodEntry entry) async {
    final db = await database;
    return await db.update(
      'moods',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> updateRemoteId(int id, String remoteId) async {
    final db = await database;
    return await db.update(
      'moods',
      {'remoteId': remoteId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSyncedFields({
    required int id,
    String? remoteId,
    String? imageUrl,
  }) async {
    final db = await database;
    final payload = <String, Object?>{};

    if (remoteId != null) {
      payload['remoteId'] = remoteId;
    }
    if (imageUrl != null) {
      payload['imageUrl'] = imageUrl;
    }
    if (payload.isEmpty) {
      return 0;
    }

    return await db.update('moods', payload, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('moods', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllEntries() async {
    final db = await database;
    await db.delete('moods');
  }

  Future<void> upsertRemoteEntry(
    MoodEntry entry, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final remoteId = entry.remoteId;
    if (remoteId == null || remoteId.isEmpty) return;

    final byRemoteId = await db.query(
      'moods',
      where: 'remoteId = ?',
      whereArgs: [remoteId],
      limit: 1,
    );

    if (byRemoteId.isNotEmpty) {
      final localId = byRemoteId.first['id'] as int;
      await db.update(
        'moods',
        entry.copyWith(id: localId).toMap(),
        where: 'id = ?',
        whereArgs: [localId],
      );
      return;
    }

    // If remote event arrives before local row receives remoteId,
    // bind by local id first to avoid creating a duplicate row.
    final localIdFromRemote = entry.id;
    if (localIdFromRemote != null) {
      final byLocalId = await db.query(
        'moods',
        where: 'id = ?',
        whereArgs: [localIdFromRemote],
        limit: 1,
      );
      if (byLocalId.isNotEmpty) {
        await db.update(
          'moods',
          entry.copyWith(id: localIdFromRemote).toMap(),
          where: 'id = ?',
          whereArgs: [localIdFromRemote],
        );
        return;
      }
    }

    await db.insert(
      'moods',
      entry.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAllRemoteEntries(List<MoodEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in entries) {
        await upsertRemoteEntry(entry, executor: txn);
      }
    });
  }

  Future<void> bindRemoteIdToLocalId({
    required int localId,
    required String remoteId,
    String? imageUrl,
  }) async {
    final db = await database;
    await db.update(
      'moods',
      {
        'remoteId': remoteId,
        'imageUrl': imageUrl,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteRemoteEntriesNotIn(Set<String> remoteIds) async {
    final db = await database;
    if (remoteIds.isEmpty) {
      await db.delete('moods', where: 'remoteId IS NOT NULL');
      return;
    }

    final placeholders = List.filled(remoteIds.length, '?').join(',');
    await db.delete(
      'moods',
      where: 'remoteId IS NOT NULL AND remoteId NOT IN ($placeholders)',
      whereArgs: remoteIds.toList(),
    );
  }
}
