import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'place_detail_screen.dart';
import 'package:geolocator/geolocator.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final savedIds = auth.appUser?.savedSpotIds ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Blue header
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Saved Places',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: savedIds.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border_rounded,
                            size: 64, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text('No saved places yet',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : StreamBuilder<List<StudySpot>>(
                    stream: FirebaseService().getSavedSpots(savedIds),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final spots = snap.data ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: spots.length,
                        itemBuilder: (_, i) => _SavedSpotCard(
                          spot: spots[i],
                          onUnsave: () {
                            if (auth.user == null) return;
                            FirebaseService().toggleSavedSpot(
                                auth.user!.uid, spots[i].id,
                                isSaved: true);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedSpotCard extends StatelessWidget {
  final StudySpot spot;
  final VoidCallback onUnsave;
  const _SavedSpotCard({required this.spot, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(spotId: spot.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: spot.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: spot.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 160,
                            width: double.infinity,
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.image_outlined,
                                size: 60, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined,
                              size: 60, color: AppColors.primary),
                        ),
                ),
                // Bookmark button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onUnsave,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.star, size: 16),
                      const SizedBox(width: 4),
                      Text(spot.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 2),
                      Text('${spot.latitude.abs().toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(spot.address,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // Amenity chips
                  Wrap(
                    spacing: 6,
                    children: [
                      if (spot.isQuiet)
                        _chip('Quiet'),
                      if (spot.hasWifi)
                        _chip('WiFi'),
                      if (spot.hasPlug)
                        _chip('Plug'),
                      if (spot.isOpenLate)
                        _chip('Open late'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(spot.openHours,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.chipText,
              fontWeight: FontWeight.w500)),
    );
  }
}
