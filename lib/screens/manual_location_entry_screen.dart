import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'notification_permission_screen.dart';
import '../core/services/mock_database.dart';

class ManualLocationEntryScreen extends StatefulWidget {
  const ManualLocationEntryScreen({super.key});

  @override
  State<ManualLocationEntryScreen> createState() =>
      _ManualLocationEntryScreenState();
}

class _ManualLocationEntryScreenState extends State<ManualLocationEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions = data['features'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  void _useCurrentLocation() {
    // This would trigger the location permission flow
    Navigator.pop(context);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _suggestions = [];
    });
  }

  void _setAsHome(String name, String addressText) {
    // Show a dialog to refine the address (house no, landmark, etc)
    final Map<String, String> parts = _parseAddress(addressText);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressRefinementSheet(
        initialName: name,
        initialCity: parts['city'] ?? '',
        initialState: parts['state'] ?? '',
        onSave: (details) async {
          final user = MockDatabase.instance.auth.currentUser;
          if (user == null) return;

          setState(() => _isLoading = true);
          try {
            await MockDatabase.instance.from('addresses').upsert({
              'user_id': user['id'],
              'house_no': details['house_no'],
              'street': details['street'] ?? name,
              'landmark': details['landmark'],
              'city': details['city'] ?? 'Unknown',
              'state': details['state'] ?? 'Unknown',
              'pincode': details['pincode'] ?? '000000',
              'address_type': 'Home',
              'is_default': true,
              'latitude': 0, // Mock lat/lng for now
              'longitude': 0,
            }).build();

            if (context.mounted) {
              Navigator.pop(context); // Close sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPermissionScreen(),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      return {
        'city': parts[parts.length - 2],
        'state': parts[parts.length - 1],
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Enter Your Location',
          style: TextStyle(
            color: Color(0xFF01102B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Garden Avenue',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.black87,
                    size: 24,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black87,
                                size: 16,
                              ),
                            ),
                            onPressed: _clearSearch,
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF01102B),
                    strokeWidth: 2,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Use Current Location Button
            InkWell(
              onTap: _useCurrentLocation,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    child: Transform.rotate(
                      angle: 0.5, // Slightly rotate right
                      child: const Icon(
                        Icons.navigation,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Use my current location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
            // Search Result Label
            if (_suggestions.isEmpty &&
                _searchController.text.isNotEmpty &&
                !_isLoading)
              Text(
                'NO RESULTS FOUND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              )
            else if (_suggestions.isNotEmpty)
              Text(
                'SUGGESTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    final properties = suggestion['properties'];
                    final name =
                        properties['name'] ??
                        properties['city'] ??
                        properties['street'] ??
                        'Unknown Location';

                    // Construct an address string
                    List<String> addressParts = [];
                    if (properties['street'] != null) {
                      addressParts.add(properties['street']);
                    }
                    if (properties['city'] != null) {
                      addressParts.add(properties['city']);
                    }
                    if (properties['state'] != null) {
                      addressParts.add(properties['state']);
                    }
                    if (properties['country'] != null) {
                      addressParts.add(properties['country']);
                    }
                    final address = addressParts.join(', ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _setAsHome(name, address),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 22,
                              color: Color(0xFF01102B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF01102B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Set as Home',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF01102B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_searchController.text.isEmpty)
              const SizedBox.shrink()
            else if (!_isLoading)
              Center(
                child: Text(
                  'No results found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressRefinementSheet extends StatefulWidget {
  final String initialName;
  final String initialCity;
  final String initialState;
  final Function(Map<String, String>) onSave;

  const _AddressRefinementSheet({
    required this.initialName,
    required this.initialCity,
    required this.initialState,
    required this.onSave,
  });

  @override
  State<_AddressRefinementSheet> createState() => _AddressRefinementSheetState();
}

class _AddressRefinementSheetState extends State<_AddressRefinementSheet> {
  late TextEditingController _houseController;
  late TextEditingController _landmarkController;
  late TextEditingController _pincodeController;
  late TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController();
    _landmarkController = TextEditingController();
    _pincodeController = TextEditingController();
    _streetController = TextEditingController(text: widget.initialName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refine your address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _buildField('House / Flat / Block No.', _houseController),
          const SizedBox(height: 12),
          _buildField('Street / Area Name', _streetController),
          const SizedBox(height: 12),
          _buildField('Landmark (Optional)', _landmarkController),
          const SizedBox(height: 12),
          _buildField('Pincode', _pincodeController, isNum: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave({
                  'house_no': _houseController.text,
                  'street': _streetController.text,
                  'landmark': _landmarkController.text,
                  'city': widget.initialCity,
                  'state': widget.initialState,
                  'pincode': _pincodeController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01102B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNum = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
