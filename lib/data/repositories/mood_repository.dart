import '../datasources/local/db_helper.dart';
import '../models/mood_entry.dart';

class MoodRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<List<MoodEntry>> getAllMoods() async {
    return await _dbHelper.getEntries();
  }

  Future<void> addMood(MoodEntry entry) async {
    await _dbHelper.insertEntry(entry);
  }

  Future<void> updateMood(MoodEntry entry) async {
    await _dbHelper.updateEntry(entry);
  }

  Future<void> deleteMood(int id) async {
    await _dbHelper.deleteEntry(id);
  }
}