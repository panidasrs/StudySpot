import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
//  STUDY SPOT MODEL
// ─────────────────────────────────────────
class StudySpot {
  final String id;
  final String name;
  final String address;
  final String openHours;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double latitude;
  final double longitude;
  final bool hasWifi;
  final bool hasPlug;
  final bool isFree;
  final bool isQuiet;
  final bool isOpenLate;
  final double quietLevel;   // 0–5
  final String wifiQuality;  // Poor / Fair / Good / Excellent
  final String plugAvailability; // Available / Limited / Not Available
  final String crowdLevel;   // Low / Medium / High
  final DateTime createdAt;
  final String createdBy;

  StudySpot({
    required this.id,
    required this.name,
    required this.address,
    required this.openHours,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.latitude,
    required this.longitude,
    required this.hasWifi,
    required this.hasPlug,
    required this.isFree,
    required this.isQuiet,
    required this.isOpenLate,
    required this.quietLevel,
    required this.wifiQuality,
    required this.plugAvailability,
    required this.crowdLevel,
    required this.createdAt,
    required this.createdBy,
  });

  factory StudySpot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySpot(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      openHours: data['openHours'] ?? '',
      category: data['category'] ?? 'Library',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      hasWifi: data['hasWifi'] ?? false,
      hasPlug: data['hasPlug'] ?? false,
      isFree: data['isFree'] ?? true,
      isQuiet: data['isQuiet'] ?? false,
      isOpenLate: data['isOpenLate'] ?? false,
      quietLevel: (data['quietLevel'] ?? 0.0).toDouble(),
      wifiQuality: data['wifiQuality'] ?? 'Good',
      plugAvailability: data['plugAvailability'] ?? 'Available',
      crowdLevel: data['crowdLevel'] ?? 'Medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'address': address,
        'openHours': openHours,
        'category': category,
        'imageUrl': imageUrl,
        'rating': rating,
        'reviewCount': reviewCount,
        'latitude': latitude,
        'longitude': longitude,
        'hasWifi': hasWifi,
        'hasPlug': hasPlug,
        'isFree': isFree,
        'isQuiet': isQuiet,
        'isOpenLate': isOpenLate,
        'quietLevel': quietLevel,
        'wifiQuality': wifiQuality,
        'plugAvailability': plugAvailability,
        'crowdLevel': crowdLevel,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };
}

// ─────────────────────────────────────────
//  REVIEW MODEL
// ─────────────────────────────────────────
class Review {
  final String id;
  final String spotId;
  final String spotName;
  final String spotImageUrl;
  final double spotDistanceKm;
  final String userId;
  final String userName;
  final double overallRating;
  final double quietRating;   // 1–5
  final double comfortRating; // 1–5
  final double wifiRating;    // 1–5
  final bool hasWifi;
  final bool hasPlug;
  final String crowdLevel;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.spotImageUrl,
    required this.spotDistanceKm,
    required this.userId,
    required this.userName,
    required this.overallRating,
    required this.quietRating,
    required this.comfortRating,
    required this.wifiRating,
    required this.hasWifi,
    required this.hasPlug,
    required this.crowdLevel,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      spotId: data['spotId'] ?? '',
      spotName: data['spotName'] ?? '',
      spotImageUrl: data['spotImageUrl'] ?? '',
      spotDistanceKm: (data['spotDistanceKm'] ?? 0.0).toDouble(),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      overallRating: (data['overallRating'] ?? 0.0).toDouble(),
      quietRating: (data['quietRating'] ?? 0.0).toDouble(),
      comfortRating: (data['comfortRating'] ?? 0.0).toDouble(),
      wifiRating: (data['wifiRating'] ?? 0.0).toDouble(),
      hasWifi: data['hasWifi'] ?? false,
      hasPlug: data['hasPlug'] ?? false,
      crowdLevel: data['crowdLevel'] ?? 'Medium',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'spotId': spotId,
        'spotName': spotName,
        'spotImageUrl': spotImageUrl,
        'spotDistanceKm': spotDistanceKm,
        'userId': userId,
        'userName': userName,
        'overallRating': overallRating,
        'quietRating': quietRating,
        'comfortRating': comfortRating,
        'wifiRating': wifiRating,
        'hasWifi': hasWifi,
        'hasPlug': hasPlug,
        'crowdLevel': crowdLevel,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ─────────────────────────────────────────
//  USER MODEL
// ─────────────────────────────────────────
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final List<String> savedSpotIds;
  final int reviewCount;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.savedSpotIds,
    required this.reviewCount,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Study Explorer',
      photoUrl: data['photoUrl'] ?? '',
      savedSpotIds: List<String>.from(data['savedSpotIds'] ?? []),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'savedSpotIds': savedSpotIds,
        'reviewCount': reviewCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
