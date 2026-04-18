import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  String _category = 'Library';
  final List<String> _categories = [
    'Library',
    'Cafe',
    'Co-working Space',
    'Classroom',
    'Outdoor',
    'Other',
  ];

  bool _hasPlug = false;
  bool _hasWifi = false;
  bool _isFree = true;
  bool _isQuiet = false;
  bool _isOpenLate = false;

  LatLng? _selectedLocation;
  File? _imageFile;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _pickLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enable in settings.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() => _selectedLocation = LatLng(pos.latitude, pos.longitude));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location set to your current position ✅')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Please try again.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a place name')));
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please pick a location on map')));
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _submitting = true);

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await FirebaseService().uploadImage(_imageFile!);
      }

      final spot = StudySpot(
        id: '',
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        openHours: _hoursCtrl.text.trim().isEmpty
            ? '8:00 AM - 10:00 PM'
            : _hoursCtrl.text.trim(),
        category: _category,
        imageUrl: imageUrl,
        rating: 0.0,
        reviewCount: 0,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        hasWifi: _hasWifi,
        hasPlug: _hasPlug,
        isFree: _isFree,
        isQuiet: _isQuiet,
        isOpenLate: _isOpenLate,
        quietLevel: 0,
        wifiQuality: _hasWifi ? 'Good' : 'None',
        plugAvailability: _hasPlug ? 'Available' : 'Not Available',
        crowdLevel: 'Low',
        createdAt: DateTime.now(),
        createdBy: auth.user!.uid,
      );

      await FirebaseService().addSpot(spot);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place added successfully! 🎉')),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Add New Place',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place Name
            _Label('Place Name'),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Enter place name'),
            ),
            const SizedBox(height: 20),

            // Category
            _Label('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Address
            _Label('Address'),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(hintText: 'Enter address'),
            ),
            const SizedBox(height: 20),

            // Open Hours
            _Label('Open Hours'),
            TextField(
              controller: _hoursCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g., 8:00 AM - 10:00 PM'),
            ),
            const SizedBox(height: 20),

            // Location picker
            _Label('Location'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedLocation != null
                          ? Icons.location_on_rounded
                          : Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedLocation != null
                          ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                          : 'Pick Location on Map',
                      style: TextStyle(
                        color: _selectedLocation != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Amenities
            _Label('Amenities'),
            const SizedBox(height: 8),
            _ToggleRow(
              label: 'Has Plug',
              value: _hasPlug,
              onChanged: (v) => setState(() => _hasPlug = v),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _ToggleRow(
              label: 'WiFi Available',
              value: _hasWifi,
              onChanged: (v) => setState(() => _hasWifi = v),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _ToggleRow(
              label: 'Free Entry',
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _ToggleRow(
              label: 'Quiet',
              value: _isQuiet,
              onChanged: (v) => setState(() => _isQuiet = v),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _ToggleRow(
              label: 'Open Late',
              value: _isOpenLate,
              onChanged: (v) => setState(() => _isOpenLate = v),
            ),
            const SizedBox(height: 20),

            // Place Image
            _Label('Place Image'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_rounded,
                              size: 32, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('Upload Image',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary)),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary),
        ],
      ),
    );
  }
}