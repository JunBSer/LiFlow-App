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
}
