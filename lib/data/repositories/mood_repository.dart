import 'dart:async';

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

    unawaited(_syncCreateToRemote(localEntry, localId));
  }

  Future<void> updateMood(MoodEntry entry) async {
    await _dbHelper.updateEntry(entry);
    unawaited(_syncUpdateToRemote(entry));
  }

  Future<void> deleteMood(int id) async {
    final localEntry = await _dbHelper.getEntryById(id);
    final remoteId = localEntry?.remoteId;
    final imageUrl = localEntry?.imageUrl;

    final deletedRows = await _dbHelper.deleteEntry(id);
    if (deletedRows == 0) {
      return;
    }
    if (remoteId == null) return;

    unawaited(_syncDeleteFromRemote(remoteId, imageUrl: imageUrl));
  }

  Future<void> _syncCreateToRemote(MoodEntry localEntry, int localId) async {
    try {
      final result = await _remote.saveMood(localEntry);
      if (result != null) {
        await _dbHelper.updateSyncedFields(
          id: localId,
          remoteId: result.remoteId,
          imageUrl: result.imageUrl,
        );
      }
    } catch (_) {
    }
  }

  Future<void> _syncUpdateToRemote(MoodEntry entry) async {
    try {
      if (entry.remoteId == null || entry.remoteId!.isEmpty) {
        final result = await _remote.saveMood(entry);
        if (result != null && entry.id != null) {
          await _dbHelper.updateSyncedFields(
            id: entry.id!,
            remoteId: result.remoteId,
            imageUrl: result.imageUrl,
          );
        }
      } else {
        final syncedImageUrl = await _remote.updateMood(entry);
        if (syncedImageUrl != null && entry.id != null) {
          await _dbHelper.updateSyncedFields(
            id: entry.id!,
            imageUrl: syncedImageUrl,
          );
        }
      }
    } catch (_) {
    }
  }

  Future<void> _syncDeleteFromRemote(
    String remoteId, {
    String? imageUrl,
  }) async {
    try {
      await _remote.deleteMood(remoteId, imageUrl: imageUrl);
    } catch (_) {
    }
  }
}
