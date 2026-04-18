import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'place_detail_screen.dart';
import 'add_place_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Position? _userPosition;

  final Set<String> _activeFilters = {};
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Quiet', 'key': 'quiet'},
    {'label': 'Has plug', 'key': 'plug'},
    {'label': 'WiFi', 'key': 'wifi'},
    {'label': 'Open late', 'key': 'late'},
    {'label': 'Free', 'key': 'free'},
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  double _distanceTo(StudySpot spot) {
    if (_userPosition == null) return double.maxFinite;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      spot.latitude,
      spot.longitude,
    ) / 1000;
  }

  List<StudySpot> _applyFiltersAndSort(List<StudySpot> spots) {
    var result = spots;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Amenity filters
    for (final f in _activeFilters) {
      switch (f) {
        case 'quiet':
          result = result.where((s) => s.isQuiet).toList();
          break;
        case 'plug':
          result = result.where((s) => s.hasPlug).toList();
          break;
        case 'wifi':
          result = result.where((s) => s.hasWifi).toList();
          break;
        case 'late':
          result = result.where((s) => s.isOpenLate).toList();
          break;
        case 'free':
          result = result.where((s) => s.isFree).toList();
          break;
      }
    }

    // เรียงตามระยะทางใกล้สุด ถ้ายังไม่มี GPS ให้เรียงตามชื่อแทน
    if (_userPosition != null) {
      result.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    } else {
      result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header ──────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      children: [
                        const Text('StudySpot',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.white),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddPlaceScreen())),
                          tooltip: 'Add new place',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search study spots...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: _filterOptions.map((f) {
                    final active = _activeFilters.contains(f['key']);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (active) {
                            _activeFilters.remove(f['key']);
                          } else {
                            _activeFilters.add(f['key'] as String);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                active ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            f['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Spots list ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<StudySpot>>(
              stream: FirebaseService().getSpotsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final spots = _applyFiltersAndSort(snap.data ?? []);
                if (spots.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text('No spots found',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        const Text('Study Places',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        if (_userPosition == null)
                          const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              SizedBox(width: 4),
                              Text('Finding location...',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.near_me,
                                  size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Nearest first',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...spots.map((s) => _SpotCard(
                          spot: s,
                          distanceKm: _userPosition != null
                              ? _distanceTo(s)
                              : null,
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spot card ────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  final StudySpot spot;
  final double? distanceKm;
  const _SpotCard({required this.spot, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(spotId: spot.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: spot.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: spot.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.primary),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.primary),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.location_on_outlined,
                            color: AppColors.primary, size: 36),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.star, size: 16),
                        const SizedBox(width: 2),
                        Text(spot.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: 2),
                        if (distanceKm != null)
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (spot.hasWifi)
                          const _AmenityChip(
                              label: 'WiFi', icon: Icons.wifi_rounded),
                        if (spot.hasPlug)
                          const _AmenityChip(
                              label: 'Plug', icon: Icons.power_outlined),
                        if (spot.isFree)
                          const _AmenityChip(
                              label: 'Free', icon: Icons.money_off_rounded),
                        if (spot.isQuiet)
                          const _AmenityChip(
                              label: 'Quiet',
                              icon: Icons.volume_off_rounded),
                        if (spot.isOpenLate)
                          const _AmenityChip(
                              label: 'Open late',
                              icon: Icons.nightlight_round),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.chipText),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.chipText,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
