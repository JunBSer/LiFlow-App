import '../datasources/local/db_helper.dart';
import '../datasources/remote/firebase_mood_remote_datasource.dart';
import '../models/mood_entry.dart';

class MoodRepository {
  final DBHelper _dbHelper = DBHelper();
  final FirebaseMoodRemoteDataSource _remote = FirebaseMoodRemoteDataSource();

  Future<List<MoodEntry>> getAllMoods() async {
    return await _dbHelper.getEntries();
  }

  Future<void> addMood(MoodEntry entry) async {
    final localId = await _dbHelper.insertEntry(entry);
    final localEntry = entry.copyWith(id: localId);

    try {
      final remoteId = await _remote.saveMood(localEntry);
      if (remoteId != null) {
        await _dbHelper.updateRemoteId(localId, remoteId);
      }
    } catch (_) {
      // Keep local-first flow even if remote sync fails.
    }
  }

  Future<void> updateMood(MoodEntry entry) async {
    await _dbHelper.updateEntry(entry);
    try {
      if (entry.remoteId == null || entry.remoteId!.isEmpty) {
        final remoteId = await _remote.saveMood(entry);
        if (remoteId != null && entry.id != null) {
          await _dbHelper.updateRemoteId(entry.id!, remoteId);
        }
      } else {
        await _remote.updateMood(entry);
      }
    } catch (_) {
      // Ignore remote errors to keep editing available offline.
    }
  }

  Future<void> deleteMood(int id) async {
    final localEntry = await _dbHelper.getEntryById(id);
    final remoteId = localEntry?.remoteId;

    await _dbHelper.deleteEntry(id);
    if (remoteId == null) return;

    try {
      await _remote.deleteMood(remoteId);
    } catch (_) {
      // Local delete should succeed regardless of remote state.
    }
  }
}
