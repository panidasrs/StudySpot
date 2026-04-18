import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  StudySpot? _selectedSpot;
  Set<Marker> _markers = {};

  // Default: Mahidol University Salaya campus
  static const LatLng _mahidolCenter = LatLng(13.7965, 100.3218);

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
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _userPosition = pos);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    } catch (_) {}
  }

  double? _distanceTo(StudySpot spot) {
    if (_userPosition == null) return null;
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          spot.latitude,
          spot.longitude,
        ) /
        1000; // แปลงจาก เมตร เป็น กิโลเมตร
  }

  void _buildMarkers(List<StudySpot> spots) {
    _markers = spots.map((spot) {
      return Marker(
        markerId: MarkerId(spot.id),
        position: LatLng(spot.latitude, spot.longitude),
        infoWindow: InfoWindow(title: spot.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedSpot?.id == spot.id
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueAzure,
        ),
        onTap: () => setState(() => _selectedSpot = spot),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        title: const Text('Map View',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB))),
      ),
      body: StreamBuilder<List<StudySpot>>(
        stream: FirebaseService().getSpotsStream(),
        builder: (ctx, snap) {
          final spots = snap.data ?? [];
          _buildMarkers(spots);

          return Stack(
            children: [
              // ── Google Map ───────────────────────────────────────────────
              GoogleMap(
                onMapCreated: (ctrl) => _mapController = ctrl,
                initialCameraPosition: const CameraPosition(
                  target: _mahidolCenter,
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) => setState(() => _selectedSpot = null),
              ),

              // ── Zoom controls ─────────────────────────────────────────────
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.add,
                      onTap: () =>
                          _mapController?.animateCamera(CameraUpdate.zoomIn()),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.remove,
                      onTap: () =>
                          _mapController?.animateCamera(CameraUpdate.zoomOut()),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.my_location_rounded,
                      onTap: _getUserLocation,
                    ),
                  ],
                ),
              ),

              // ── Selected spot card ────────────────────────────────────────
              if (_selectedSpot != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _SpotPreviewCard(
                    spot: _selectedSpot!,
                    distanceKm: _distanceTo(_selectedSpot!),
                    onViewDetails: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PlaceDetailScreen(spotId: _selectedSpot!.id)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SpotPreviewCard extends StatelessWidget {
  final StudySpot spot;
  final double? distanceKm;
  final VoidCallback onViewDetails;
  const _SpotPreviewCard({
    required this.spot,
    required this.distanceKm,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: spot.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: spot.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.primary),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.primary),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 32),
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
                        color: AppColors.star, size: 14),
                    const SizedBox(width: 2),
                    Text(spot.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.textSecondary, size: 13),
                    const SizedBox(width: 2),
                    if (distanceKm != null)
                      Text('${distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary))
                    else
                      const Text('-- km',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(90, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('View details'),
          ),
        ],
      ),
    );
  }
}