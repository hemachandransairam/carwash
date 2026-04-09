import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'manual_location_entry_screen.dart';
import 'notification_permission_screen.dart';
import '../core/services/mock_database.dart';

// Bangalore bounding box (approximate)
const double _bangaloreLatMin = 12.834;
const double _bangaloreLatMax = 13.144;
const double _bangaloreLngMin = 77.460;
const double _bangaloreLngMax = 77.780;

bool _isWithinBangalore(double lat, double lng) {
  return lat >= _bangaloreLatMin &&
      lat <= _bangaloreLatMax &&
      lng >= _bangaloreLngMin &&
      lng <= _bangaloreLngMax;
}

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingLocation();
  }

  Future<void> _checkExistingLocation() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      // Check if user already has any address saved in the addresses table
      final addressData = await MockDatabase.instance
          .from('addresses')
          .select('id')
          .eq('user_id', user['id'])
          .limit(1)
          .maybeSingle()
          .build<Map<String, dynamic>?>();

      if (addressData != null) {
        // Address already exists, skip this screen
        if (mounted) {
          _navigateToNext();
        }
      }
    }
  }

  void _navigateToNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPermissionScreen(),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _locationMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _locationMessage = 'Location services are disabled. Please enable them.';
        });
        _showLocationDialog(
          'Location Services Disabled',
          'Please enable location services in your device settings.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _locationMessage = 'Location permission denied';
          });
          // Offer manual entry instead of dead-end
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _locationMessage = 'Location permissions are permanently denied';
        });
        _showPermissionDeniedDialog(permanent: true);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Reverse Geocode to get address string
      String city = "Bangalore";
      String street = "Current Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          city = p.locality ?? "Bangalore";
          street = p.subLocality ?? p.street ?? "Current Location";
        }
      } catch (geoError) {
        debugPrint("Geocoding failed: $geoError");
      }

      // Save to addresses table instead of users table
      final user = MockDatabase.instance.auth.currentUser;
      if (user != null) {
        try {
          await MockDatabase.instance.from('addresses').insert({
            'user_id': user['id'],
            'address_type': 'Current',
            'house_no': '📍',
            'street': street,
            'city': city,
            'is_default': true,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }).build();
          
          debugPrint("Location saved to addresses table");
        } catch (dbError) {
          debugPrint("Database Save Error: $dbError");
        }
      }

      setState(() {
        _isLoading = false;
        _locationMessage = 'Location: $street, $city';
      });

      // Check if within Bangalore
      if (!_isWithinBangalore(position.latitude, position.longitude)) {
        if (mounted) _showOutsideBangaloreScreen();
        return;
      }

      if (mounted) {
        _navigateToNext();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationMessage = 'Error: $e';
      });
      _showLocationDialog('Error', 'Failed to get location. Please enter your location manually.');
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  /// Shows when permission is denied — offers manual entry instead of dead-end
  void _showPermissionDeniedDialog({bool permanent = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(permanent ? 'Permission Permanently Denied' : 'Permission Denied'),
        content: const Text(
          'Location access is needed to find services near you. You can enter your location manually instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enterLocationManually();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01102B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enter Manually', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Shows when location is outside Bangalore service area
  void _showOutsideBangaloreScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const _OutsideBangaloreScreen(),
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
                            color: Colors.black.withValues(alpha: 0.05),
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
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
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

/// Shown when the user's detected location is outside Bangalore service area
class _OutsideBangaloreScreen extends StatelessWidget {
  const _OutsideBangaloreScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 80,
                color: Color(0xFF01102B),
              ),
              const SizedBox(height: 32),
              const Text(
                'Not Available Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF01102B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We are yet to onboard your location, please try again later.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7D7D7D),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01102B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
