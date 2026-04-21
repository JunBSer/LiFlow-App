import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/services/firebase_service.dart';
import '../../models/mood_entry.dart';

class RemoteMoodSyncResult {
  final String remoteId;
  final String? imageUrl;

  const RemoteMoodSyncResult({required this.remoteId, this.imageUrl});
}

class FirebaseMoodRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool get canUseRemote => FirebaseService.isReady;

  Future<RemoteMoodSyncResult?> saveMood(MoodEntry entry) async {
    if (!canUseRemote) return null;

    var imageUrl = entry.imageUrl;
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = await _uploadImage(imageUrl);
    }

    final doc = await _firestore.collection('moods').add({
      'localId': entry.id,
      'emoji': entry.emoji,
      'reason': entry.reason,
      'category': entry.category,
      'keywords': entry.keywords,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(entry.dateTime),
    });

    return RemoteMoodSyncResult(remoteId: doc.id, imageUrl: imageUrl);
  }

  Future<String?> updateMood(MoodEntry entry) async {
    if (!canUseRemote || entry.remoteId == null || entry.remoteId!.isEmpty) {
      return null;
    }

    var imageUrl = entry.imageUrl;
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = await _uploadImage(imageUrl);
    }

    await _firestore.collection('moods').doc(entry.remoteId).update({
      'emoji': entry.emoji,
      'reason': entry.reason,
      'category': entry.category,
      'keywords': entry.keywords,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(entry.dateTime),
    });

    return imageUrl;
  }

  Future<void> deleteMood(String remoteId, {String? imageUrl}) async {
    if (!canUseRemote || remoteId.isEmpty) return;

    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (_) {
      }
    }

    await _firestore.collection('moods').doc(remoteId).delete();
  }

  Future<String> _uploadImage(String localPath) async {
    final file = File(localPath);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref('mood_images/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
