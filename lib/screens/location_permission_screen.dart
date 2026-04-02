import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'manual_location_entry_screen.dart';
import 'notification_permission_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  String? _locationMessage;

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _locationMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _locationMessage =
              'Location services are disabled. Please enable them.';
        });
        _showLocationDialog(
          'Location Services Disabled',
          'Please enable location services in your device settings.',
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _locationMessage = 'Location permission denied';
          });
          _showLocationDialog(
            'Permission Denied',
            'Location permission is required to find nearby service providers.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _locationMessage = 'Location permissions are permanently denied';
        });
        _showLocationDialog(
          'Permission Permanently Denied',
          'Please enable location permission in app settings.',
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isLoading = false;
        _locationMessage =
            'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });

      // Navigate to Notification Permission Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPermissionScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationMessage = 'Error: $e';
      });
      _showLocationDialog('Error', 'Failed to get location: $e');
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _enterLocationManually() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualLocationEntryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Location Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Color(0xFF01102B),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Heading
                    const Text(
                      "What's Your Location?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01102B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    const Text(
                      'To Find Nearby Service Provider.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7D7D7D),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Allow Location Access Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _requestLocationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF01102B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Allow Location Access',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Enter Location Manually Button
                    TextButton(
                      onPressed: _enterLocationManually,
                      child: const Text(
                        'Enter Location Manually',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01102B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Location Message Display
                    if (_locationMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _locationMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF01102B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
