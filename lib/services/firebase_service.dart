import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/models.dart';
import 'cloudinary_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': email.split('@')[0],
      'photoUrl': '',
      'savedSpotIds': [],
      'reviewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AppUser?> getUserStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);

  Future<void> updateDisplayName(String uid, String name) =>
      _db.collection('users').doc(uid).update({'displayName': name});

  Stream<List<StudySpot>> getSpotsStream() => _db
      .collection('studySpots')
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(StudySpot.fromFirestore).toList());

  Future<StudySpot?> getSpot(String spotId) async {
    final doc = await _db.collection('studySpots').doc(spotId).get();
    return doc.exists ? StudySpot.fromFirestore(doc) : null;
  }

  Future<String> addSpot(StudySpot spot) async {
    final ref = await _db.collection('studySpots').add(spot.toFirestore());
    return ref.id;
  }

  Stream<List<Review>> getReviewsForSpot(String spotId) => _db
      .collection('reviews')
      .where('spotId', isEqualTo: spotId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Review.fromFirestore).toList());

  Stream<List<Review>> getReviewsByUser(String userId) => _db
      .collection('reviews')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Review.fromFirestore).toList());

  Future<void> addReview(Review review) async {
    // 1. บันทึก review ก่อน
    await _db.collection('reviews').add(review.toFirestore());

    // 2. อัปเดต rating ของ spot โดยไม่ใช้ transaction (ป้องกัน not-found error)
    final spotRef = _db.collection('studySpots').doc(review.spotId);
    final spotSnap = await spotRef.get();

    if (spotSnap.exists) {
      final data = spotSnap.data() as Map<String, dynamic>;
      final oldCount = (data['reviewCount'] ?? 0) is int
          ? (data['reviewCount'] ?? 0) as int
          : ((data['reviewCount'] ?? 0) as num).toInt();
      final oldRating = (data['rating'] ?? 0.0) is double
          ? (data['rating'] ?? 0.0) as double
          : ((data['rating'] ?? 0.0) as num).toDouble();
      final newCount = oldCount + 1;
      final newRating =
          ((oldRating * oldCount) + review.overallRating) / newCount;

      await spotRef.update({
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'reviewCount': newCount,
        'quietLevel': review.quietRating,
        'crowdLevel': review.crowdLevel,
      });
    }

    // 3. อัปเดต reviewCount ของ user
    final userRef = _db.collection('users').doc(review.userId);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      await userRef.update({'reviewCount': FieldValue.increment(1)});
    }
  }

  Future<void> deleteReview(String reviewId, String spotId,
    double rating, String userId) async {
  // ลบ review document
  await _db.collection('reviews').doc(reviewId).delete();

  // อัปเดต rating ของ spot
  final spotSnap = await _db.collection('studySpots').doc(spotId).get();
  if (spotSnap.exists) {
    final data = spotSnap.data() as Map<String, dynamic>;
    final oldCount = ((data['reviewCount'] ?? 1) as num).toInt();
    final oldRating = ((data['rating'] ?? 0.0) as num).toDouble();
    final newCount = oldCount - 1;
    if (newCount <= 0) {
      await _db.collection('studySpots').doc(spotId).update({
        'rating': 0.0,
        'reviewCount': 0,
      });
    } else {
      final newRating = ((oldRating * oldCount) - rating) / newCount;
      await _db.collection('studySpots').doc(spotId).update({
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'reviewCount': newCount,
      });
    }
  }

  // ลด reviewCount ของ user
  await _db.collection('users').doc(userId).update({
    'reviewCount': FieldValue.increment(-1),
  });
}

  Future<void> toggleSavedSpot(String userId, String spotId,
    {required bool isSaved}) async {
  final userRef = _db.collection('users').doc(userId);
  if (isSaved) {
    await userRef.set({
      'savedSpotIds': FieldValue.arrayRemove([spotId])
    }, SetOptions(merge: true));
  } else {
    await userRef.set({
      'savedSpotIds': FieldValue.arrayUnion([spotId])
    }, SetOptions(merge: true));
  }
}
  Stream<List<StudySpot>> getSavedSpots(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    return _db
        .collection('studySpots')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snap) => snap.docs.map(StudySpot.fromFirestore).toList());
  }

  Future<String> uploadImage(File file) async {
    return await CloudinaryService.uploadImage(file);
  }
}
