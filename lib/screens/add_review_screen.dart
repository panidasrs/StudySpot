import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class AddReviewScreen extends StatefulWidget {
  final StudySpot spot;
  const AddReviewScreen({super.key, required this.spot});
  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _overallRating = 0;
  double _quietRating = 4;
  double _comfortRating = 4;
  bool _hasWifi = false;
  bool _hasPlug = false;
  String _crowdLevel = 'Medium';
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  Future<double> _getDistanceKm() async {
  try {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return 0.0;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );

    final distanceMeters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.spot.latitude,
      widget.spot.longitude,
    );

    return double.parse((distanceMeters / 1000).toStringAsFixed(1));
  } catch (_) {
    return 0.0;
  }
}

  Future<void> _submit() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an overall rating')));
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    setState(() => _submitting = true);
    try {
      final review = Review(
        id: '',
        spotId: widget.spot.id,
        spotName: widget.spot.name,
        spotImageUrl: widget.spot.imageUrl,
        spotDistanceKm: await _getDistanceKm(),
        userId: auth.user!.uid,
        userName: auth.appUser?.displayName ?? 'Anonymous',
        overallRating: _overallRating,
        quietRating: _quietRating,
        comfortRating: _comfortRating,
        wifiRating: _hasWifi ? 5 : 1,
        hasWifi: _hasWifi,
        hasPlug: _hasPlug,
        crowdLevel: _crowdLevel,
        comment: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await FirebaseService().addReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Add Review',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Center(
              child: RatingBar.builder(
                initialRating: _overallRating,
                minRating: 1,
                itemSize: 44,
                unratedColor: const Color(0xFFE5E7EB),
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.star),
                onRatingUpdate: (r) => setState(() => _overallRating = r),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Detailed Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _buildSlider('Quiet', _quietRating, (v) => setState(() => _quietRating = v)),
            const SizedBox(height: 16),
            _buildSlider('Comfort', _comfortRating, (v) => setState(() => _comfortRating = v)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _ToggleCard(label: 'Wi-Fi', value: _hasWifi, onChanged: (v) => setState(() => _hasWifi = v))),
              const SizedBox(width: 12),
              Expanded(child: _ToggleCard(label: 'Plug', value: _hasPlug, onChanged: (v) => setState(() => _hasPlug = v))),
            ]),
            const SizedBox(height: 24),
            const Text('Crowd Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(children: ['Low', 'Medium', 'High'].map((level) {
              final sel = _crowdLevel == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _crowdLevel = level),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryLight : Colors.white,
                      border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB), width: sel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(level, style: TextStyle(fontWeight: FontWeight.w500, color: sel ? AppColors.primary : AppColors.textSecondary, fontSize: 14)),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 24),
            const Text('Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                fillColor: const Color(0xFFF9FAFB),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            Text('${value.toInt()}/5', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFE5E7EB),
            thumbColor: Colors.white,
          ),
          child: Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleCard({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
