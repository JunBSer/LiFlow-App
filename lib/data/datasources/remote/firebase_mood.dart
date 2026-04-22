import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../../models/mood_entry.dart';

class RemoteMoodSyncResult {
  final String remoteId;
  final String? imageUrl;

  const RemoteMoodSyncResult({required this.remoteId, this.imageUrl});
}

class FirebaseMoodRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get canUseRemote => FirebaseService.isReady;
  String? get _currentUserId => _auth.currentUser?.uid;

  Future<RemoteMoodSyncResult?> saveMood(
    MoodEntry entry, {
    String? cloudImageUrl,
  }) async {
    final userId = _currentUserId;
    if (!canUseRemote || userId == null) return null;

    final doc = await _firestore.collection('moods').add({
      'userId': userId,
      'localId': entry.id,
      'emoji': entry.emoji,
      'reason': entry.reason,
      'category': entry.category,
      'keywords': entry.keywords,
      'imageUrl': cloudImageUrl ?? entry.imageUrl,
      'createdAt': Timestamp.fromDate(entry.dateTime),
    });

    return RemoteMoodSyncResult(
      remoteId: doc.id,
      imageUrl: cloudImageUrl ?? entry.imageUrl,
    );
  }

  Future<String?> updateMood(MoodEntry entry, {String? cloudImageUrl}) async {
    final userId = _currentUserId;
    if (!canUseRemote ||
        userId == null ||
        entry.remoteId == null ||
        entry.remoteId!.isEmpty) {
      return null;
    }

    final String? finalUrl = cloudImageUrl ?? entry.imageUrl;

    await _firestore.collection('moods').doc(entry.remoteId).update({
      'userId': userId,
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
    if (!canUseRemote || _currentUserId == null || remoteId.isEmpty) return;
    await _firestore.collection('moods').doc(remoteId).delete();
  }

  Future<List<MoodEntry>> fetchAllMoods() async {
    final userId = _currentUserId;
    if (!canUseRemote || userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: userId)
          .get();

      final moods = snapshot.docs.map((doc) {
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

      moods.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return moods;
    } catch (e) {
      developer.log('Error fetching from Firestore: $e');
      return [];
    }
  }

  Stream<List<MoodEntry>> watchAllMoods() {
    final userId = _currentUserId;
    if (!canUseRemote || userId == null) {
      return const Stream<List<MoodEntry>>.empty();
    }

    return _firestore
        .collection('moods')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final moods = snapshot.docs.map((doc) {
            final data = doc.data();
            return MoodEntry(
              id: data['localId'],
              remoteId: doc.id,
              emoji: data['emoji'] ?? '',
              reason: data['reason'] ?? '',
              category: data['category'] ?? 'General',
              keywords: List<String>.from(data['keywords'] ?? const []),
              imageUrl: data['imageUrl'],
              dateTime: (data['createdAt'] as Timestamp).toDate(),
            );
          }).toList();

          moods.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          return moods;
        });
  }
}
