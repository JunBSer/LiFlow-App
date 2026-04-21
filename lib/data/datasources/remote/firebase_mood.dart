import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../../models/mood_entry.dart';

class RemoteMoodSyncResult {
  final String remoteId;
  final String? imageUrl;

  const RemoteMoodSyncResult({required this.remoteId, this.imageUrl});
}

class FirebaseMoodRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get canUseRemote => FirebaseService.isReady;

  Future<RemoteMoodSyncResult?> saveMood(MoodEntry entry, {String? cloudImageUrl}) async {
    if (!canUseRemote) return null;

    final doc = await _firestore.collection('moods').add({
      'localId': entry.id,
      'emoji': entry.emoji,
      'reason': entry.reason,
      'category': entry.category,
      'keywords': entry.keywords,
      'imageUrl': cloudImageUrl ?? entry.imageUrl,
      'createdAt': Timestamp.fromDate(entry.dateTime),
    });

    return RemoteMoodSyncResult(remoteId: doc.id, imageUrl: cloudImageUrl ?? entry.imageUrl);
  }

  Future<String?> updateMood(MoodEntry entry, {String? cloudImageUrl}) async {
    if (!canUseRemote || entry.remoteId == null || entry.remoteId!.isEmpty) {
      return null;
    }

    final String? finalUrl = cloudImageUrl ?? entry.imageUrl;

    await _firestore.collection('moods').doc(entry.remoteId).update({
      'emoji': entry.emoji,
      'reason': entry.reason,
      'category': entry.category,
      'keywords': entry.keywords,
      'imageUrl': finalUrl,
      'createdAt': Timestamp.fromDate(entry.dateTime),
    });

    return finalUrl;
  }

  Future<void> deleteMood(String remoteId, {String? imageUrl}) async {
    if (!canUseRemote || remoteId.isEmpty) return;
    await _firestore.collection('moods').doc(remoteId).delete();
  }


  Future<List<MoodEntry>> fetchAllMoods() async {
    if (!canUseRemote) return [];

    try {
      final snapshot = await _firestore
          .collection('moods')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MoodEntry(
          id: data['localId'],
          remoteId: doc.id,
          emoji: data['emoji'] ?? '',
          reason: data['reason'] ?? '',
          category: data['category'] ?? 'General',
        
          keywords: List<String>.from(data['keywords'] ?? []),
          imageUrl: data['imageUrl'],
        
          dateTime: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      developer.log('Error fetching from Firestore: $e');
      return [];
    }
  }
}