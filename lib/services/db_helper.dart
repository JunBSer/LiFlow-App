import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mood_entry.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            emoji TEXT NOT NULL,
            reason TEXT NOT NULL,
            dateTime TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(MoodEntry entry) async {
    final db = await database;
    return await db.insert('moods', entry.toMap());
  }

  Future<List<MoodEntry>> getEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('moods', orderBy: 'dateTime DESC');
    return maps.map((e) => MoodEntry.fromMap(e)).toList();
  }

  Future<int> updateEntry(MoodEntry entry) async {
    final db = await database;
    return await db.update('moods', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('moods', where: 'id = ?', whereArgs: [id]);
  }
}