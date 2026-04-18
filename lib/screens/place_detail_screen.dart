import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'add_review_screen.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String spotId;
  const PlaceDetailScreen({super.key, required this.spotId});

  Future<void> _openMaps(StudySpot spot) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final svc = FirebaseService();

    return FutureBuilder<StudySpot?>(
      future: svc.getSpot(spotId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final spot = snap.data;
        if (spot == null) {
          return const Scaffold(
              body: Center(child: Text('Spot not found')));
        }

        final isSaved =
            auth.appUser?.savedSpotIds.contains(spotId) ?? false;

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              // ── Hero image ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      if (auth.user == null) return;
                      svc.toggleSavedSpot(auth.user!.uid, spotId,
                          isSaved: isSaved);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color:
                            isSaved ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: spot.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: spot.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined,
                              size: 80, color: AppColors.primary),
                        ),
                ),
              ),

              // ── Detail content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(spot.name,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      // Stars
                      Row(
                        children: [
                          ...List.generate(
                              5,
                              (i) => Icon(
                                    i < spot.rating.floor()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: AppColors.star,
                                    size: 22,
                                  )),
                          const SizedBox(width: 6),
                          Text(spot.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          Text(' (${spot.reviewCount})',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(spot.address,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Hours
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text(spot.openHours,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Information section ───────────────────────────────
                      const Text('Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),

                      // Quiet level bar
                      _InfoRow(
                        icon: Icons.volume_off_rounded,
                        label: 'Quiet Level',
                        trailing: Text(
                          '${spot.quietLevel.toInt()}/5',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        hasBar: true,
                        barValue: spot.quietLevel / 5,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.wifi_rounded,
                        label: 'WiFi Quality',
                        trailing: Text(
                          spot.wifiQuality,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.power_outlined,
                        label: 'Plug Availability',
                        trailing: Text(
                          spot.plugAvailability,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Crowd Level',
                        trailing: Text(
                          spot.crowdLevel,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Buttons ──────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openMaps(spot),
                              icon: const Icon(Icons.location_on_outlined,
                                  size: 18),
                              label: const Text('Get Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          AddReviewScreen(spot: spot))),
                              icon: const Icon(Icons.star_border_rounded,
                                  size: 18),
                              label: const Text('Add Review'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (auth.user == null) return;
                            svc.toggleSavedSpot(auth.user!.uid, spotId,
                                isSaved: isSaved);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isSaved
                                  ? 'Removed from saved places'
                                  : 'Saved to your places!'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                          ),
                          label: Text(isSaved ? 'Saved' : 'Save'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSaved
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            side: BorderSide(
                              color: isSaved
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB),
                            ),
                            backgroundColor: isSaved
                                ? AppColors.primaryLight
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool hasBar;
  final double barValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.hasBar = false,
    this.barValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
            trailing,
          ],
        ),
        if (hasBar) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}
