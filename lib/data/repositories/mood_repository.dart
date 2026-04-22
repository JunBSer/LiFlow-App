import 'dart:async';
import 'dart:developer' as developer;

import '../datasources/local/db_helper.dart';
import '../datasources/remote/firebase_mood.dart';
import '../datasources/remote/imagekit.dart';
import '../models/mood_entry.dart';

class MoodRepository {
  final DBHelper _dbHelper = DBHelper();
  final FirebaseMoodRemoteDataSource _remote = FirebaseMoodRemoteDataSource();
  final ImageKitDataSource _imageKit = ImageKitDataSource();

  void Function()? onSyncCompleted;

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
    if (deletedRows == 0) return;

    if (remoteId != null) {
      unawaited(_syncDeleteFromRemote(remoteId, imageUrl: imageUrl));
    }
  }

  Future<void> syncFromRemote() async {
    try {
      final remoteEntries = await _remote.fetchAllMoods();
      if (remoteEntries.isEmpty) return;
      await _dbHelper.upsertAllRemoteEntries(remoteEntries);
      onSyncCompleted?.call();
    } catch (e) {
      developer.log('Error during initial sync: $e');
    }
  }

  Stream<List<MoodEntry>> watchRemoteMoods() {
    return _remote.watchAllMoods();
  }

  Future<void> applyRemoteSnapshot(List<MoodEntry> remoteEntries) async {
    final remoteIds = <String>{};
    for (final entry in remoteEntries) {
      final remoteId = entry.remoteId;
      if (remoteId == null || remoteId.isEmpty) continue;
      remoteIds.add(remoteId);
      await _dbHelper.upsertRemoteEntry(entry);
    }

    await _dbHelper.deleteRemoteEntriesNotIn(remoteIds);
    onSyncCompleted?.call();
  }

  Future<void> clearLocalData() async {
    await _dbHelper.clearAllEntries();
  }

  Future<void> syncPendingMoods() async {
    try {
      final allEntries = await _dbHelper.getEntries();
      final unsynced = allEntries.where(
        (e) => e.remoteId == null || e.remoteId!.isEmpty,
      );

      for (final entry in unsynced) {
        if (entry.id != null) {
          unawaited(_syncCreateToRemote(entry, entry.id!));
        }
      }
    } catch (e) {
      developer.log('Error syncing pending moods: $e');
    }
  }

  Future<void> _syncCreateToRemote(MoodEntry localEntry, int localId) async {
    try {
      String? cloudUrl = localEntry.imageUrl;

      if (cloudUrl != null &&
          cloudUrl.isNotEmpty &&
          !cloudUrl.startsWith('http')) {
        cloudUrl = await _imageKit.uploadImage(cloudUrl);
      }

      final result = await _remote.saveMood(
        localEntry,
        cloudImageUrl: cloudUrl,
      );

      if (result != null) {
        await _dbHelper.bindRemoteIdToLocalId(
          localId: localId,
          remoteId: result.remoteId,
          imageUrl: cloudUrl ?? result.imageUrl,
        );
        onSyncCompleted?.call();
      }
    } catch (e) {
      developer.log('Sync Create failed: $e');
    }
  }

  Future<void> _syncUpdateToRemote(MoodEntry entry) async {
    try {
      String? cloudUrl = entry.imageUrl;

      if (cloudUrl != null &&
          cloudUrl.isNotEmpty &&
          !cloudUrl.startsWith('http')) {
        cloudUrl = await _imageKit.uploadImage(cloudUrl);
      }

      if (entry.remoteId == null || entry.remoteId!.isEmpty) {
        final result = await _remote.saveMood(entry, cloudImageUrl: cloudUrl);
        if (result != null && entry.id != null) {
          await _dbHelper.updateSyncedFields(
            id: entry.id!,
            remoteId: result.remoteId,
            imageUrl: cloudUrl ?? result.imageUrl,
          );
          onSyncCompleted?.call();
        }
      } else {
        final syncedImageUrl = await _remote.updateMood(
          entry,
          cloudImageUrl: cloudUrl,
        );
        if (entry.id != null) {
          await _dbHelper.updateSyncedFields(
            id: entry.id!,
            imageUrl: cloudUrl ?? syncedImageUrl,
          );
          onSyncCompleted?.call();
        }
      }
    } catch (e) {
      developer.log('Sync Update failed: $e');
    }
  }

  Future<void> _syncDeleteFromRemote(
    String remoteId, {
    String? imageUrl,
  }) async {
    try {
      await _remote.deleteMood(remoteId, imageUrl: imageUrl);
    } catch (e) {
      developer.log('Sync Delete failed: $e');
    }
  }
}
