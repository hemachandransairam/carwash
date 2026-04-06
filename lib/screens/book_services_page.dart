import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../auth/complete_profile.dart';
import '../core/services/mock_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ccwink/screens/booking_summary_page.dart';
import 'package:ccwink/screens/select_vehicle_screen.dart';
import '../widgets/custom_widgets.dart';

class BookServicesPage extends StatefulWidget {
  const BookServicesPage({super.key});

  @override
  State<BookServicesPage> createState() => _BookServicesPageState();
}

class _BookServicesPageState extends State<BookServicesPage> {
  int _currentStep = 0;
  double _latitude = 0.0;
  double _longitude = 0.0;

  // Vehicle selection
  final Set<String> _selectedVehicleIds = {};
  String? _selectedVehicleType;
  String? _selectedVehicleBrand;
  String? _selectedVehicleModel;
  String? _selectedVehicleLicense;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _savedVehicles = [];
  bool _isLoadingVehicles = true;

  // Time selection
  DateTime _selectedDate = DateTime.now();
  DateTime _rowStartDate = DateTime.now();
  String _selectedTime = "";

  // Services selection
  final Set<String> _selectedServiceIds = {};
  List<Map<String, dynamic>> _availableServices = [];
  bool _isLoadingServices = true;
  // A matrix of [service_id][vehicle_type] -> price
  final Map<String, Map<String, double>> _pricingMatrix = {};

  // Slot selection logic dependencies
  List<Map<String, dynamic>> _activeWorkers = [];
  List<Map<String, dynamic>> _dayBookings = [];
  bool _isLoadingSlots = true;

  IconData _getIconForService(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('exterior')) return Icons.local_car_wash;
    if (lower.contains('vacuum')) return Icons.cleaning_services;
    if (lower.contains('interior')) return Icons.airline_seat_recline_extra;
    if (lower.contains('engine')) return Icons.engineering;
    if (lower.contains('polish')) return Icons.auto_fix_high;
    if (lower.contains('tire')) return Icons.tire_repair;
    if (lower.contains('wax')) return Icons.auto_fix_normal;
    return Icons.settings_suggest;
  }

  List<String> _getChecklistForService(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('express') || lower.contains('exterior')) {
      return ["Outside foam wash", "Interior mat cleaning", "Tyre polishing"];
    } else if (lower.contains('interior') || lower.contains('deep')) {
      return ["Outside foam wash", "Interior vacuuming & mat cleaning", "Dashboard and door pad", "Tyre polishing"];
    } else if (lower.contains('spa') || lower.contains('complete')) {
      return ["Outside foam wash", "Interior deep cleaning", "Exterior rubbing & waxing", "Complete detailing"];
    }
    return ["Standard inspection", "Eco-friendly products used"];
  }

  String _getCategoryBadgeForVehicle() {
    final type = _selectedVehicleType?.toLowerCase() ?? "";
    if (type.contains('suv') || type.contains('muv') || type.contains('luxury')) {
      return "ELITE CATEGORY";
    }
    return "CLASSIC CATEGORY";
  }

  double get _totalPrice {
    double total = 0;
    // For each vehicle, sum its specific service prices
    for (var vehicleId in _selectedVehicleIds) {
      final vehicle = _savedVehicles.firstWhere((v) => v['id'] == vehicleId, orElse: () => {});
      final vType = (vehicle['vehicle_type'] as String?)?.toUpperCase() ?? "SEDAN";
      
      for (var sId in _selectedServiceIds) {
        // Look up price in matrix for THIS car's type, or fallback to base_price from _availableServices if needed
        final price = _pricingMatrix[sId]?[vType];
        if (price != null) {
          total += price;
        } else {
          // Fallback to base_price if type not specifically mapped
          final baseS = _availableServices.firstWhere((s) => s['id'] == sId, orElse: () => {});
          total += (baseS['base_price'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return total;
  }

  // Address selection
  final TextEditingController _addressController = TextEditingController();
  String? _addressLabel;
  List<Map<String, dynamic>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _checkProfileCompleteness();
    _fetchVehicles();
    _fetchAddresses();
    _fetchServices();
    _fetchSlotData();
  }

  Future<void> _fetchSlotData() async {
    setState(() => _isLoadingSlots = true);
    try {
      final workersResponse = await MockDatabase.instance.client
          .from('workers')
          .select()
          .build<List<Map<String, dynamic>>>();

      // Filter APPROVED workers locally to avoid DB case-sensitivity issues
      final workers = workersResponse.where((w) {
         final status = w['status']?.toString().toUpperCase() ?? '';
         return status == 'APPROVED' || status == 'ACTIVE';
      }).toList();

      final selectedIso = _selectedDate.toUtc().toIso8601String().split('T')[0];
      final nextDayIso = _selectedDate.add(const Duration(days: 1)).toUtc().toIso8601String().split('T')[0];
      
      final bookingsResponse = await MockDatabase.instance.client
          .from('bookings')
          .select() // Just select all to avoid column miss errors!
          .gte('scheduled_at', selectedIso)
          .lt('scheduled_at', nextDayIso)
          .build<List<Map<String, dynamic>>>();

      // Filter non-cancelled locally
      final bookings = bookingsResponse.where((b) {
         final status = b['status']?.toString().toUpperCase() ?? '';
         return status != 'CANCELLED' && status != 'REJECTED';
      }).toList();

      if (mounted) {
        setState(() {
          _activeWorkers = workers;
          _dayBookings = bookings;
          _isLoadingSlots = false;
        });
      }
    } catch(e) {
      debugPrint("Error fetching slot data: $e");
      if (mounted) {
        setState(() {
          _activeWorkers = []; // Force empty safely
          _dayBookings = [];
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _fetchServices() async {
    try {
      // 1. Fetch core services
      final servicesData = await MockDatabase.instance
          .from('services')
          .select()
          .eq('is_active', true)
          .order('name')
          .build<List<Map<String, dynamic>>>();

      // 2. Fetch ALL pricing data to build the matrix
      final pricingData = await MockDatabase.instance
          .from('service_pricing')
          .select()
          .build<List<Map<String, dynamic>>>();

      _pricingMatrix.clear();
      for (var p in pricingData) {
        final sId = p['service_id'] as String;
        final vType = (p['vehicle_type'] as String).toUpperCase();
        final price = (p['price'] as num).toDouble();
        
        _pricingMatrix.putIfAbsent(sId, () => {});
        _pricingMatrix[sId]![vType] = price;
      }
      
      setState(() {
        _availableServices = servicesData.map((s) {
          // Use first car's type as the visual reference in the list for now
          final firstType = (_selectedVehicleType ?? "SEDAN").toUpperCase();
          final double finalPrice = _pricingMatrix[s['id']]?[firstType] ?? (s['base_price'] as num).toDouble();
          
          return {
            ...s,
            'price': finalPrice,
            'icon': _getIconForService(s['name']),
          };
        }).toList();
        _isLoadingServices = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  void _checkProfileCompleteness() {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      final name = user['name']?.toString() ?? '';
      if (name.isEmpty) {
        // If profile is incomplete, redirect to complete it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
            );
          }
        });
      }
    }
  }

  Future<void> _fetchVehicles() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      try {
        final data = await MockDatabase.instance
            .from('vehicles')
            .select()
            .eq('user_id', user['id'])
            .build();
        if (mounted) {
          setState(() {
            _savedVehicles = List<Map<String, dynamic>>.from(data);
            _isLoadingVehicles = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingVehicles = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = [
      addr['house_no'],
      addr['street'],
      addr['landmark'] != null && addr['landmark'].isNotEmpty ? 'Near ${addr['landmark']}' : null,
      addr['city'],
      addr['pincode'],
    ].where((e) => e != null && e.toString().isNotEmpty);
    return parts.isEmpty ? "No address details" : parts.join(", ");
  }

  Future<void> _fetchAddresses() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      try {
        final data = await MockDatabase.instance
            .from('addresses')
            .select()
            .eq('user_id', user['id'])
            .build();
        if (mounted) {
          setState(() {
            _savedAddresses = List<Map<String, dynamic>>.from(data);
            // Set default address if exists
            if (_savedAddresses.isNotEmpty && _addressController.text.isEmpty) {
              final def = _savedAddresses.firstWhere((a) => a['is_default'] == true, orElse: () => _savedAddresses.first);
              _addressController.text = _formatAddress(def);
              _addressLabel = def['address_type'] ?? "Saved";
            }
          });
        }
      } catch (e) {
        // Ignored
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      // Navigate to booking summary
      if (_canContinue()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BookingSummaryPage(
                  selectedServices:
                      _availableServices
                          .where((s) => _selectedServiceIds.contains(s['id']))
                          .toList(),
                  selectedVehicles: _savedVehicles.where((v) => _selectedVehicleIds.contains(v['id'])).toList(),
                  totalPrice: _totalPrice,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  addressText: _addressController.text,
                  addressLabel: _addressLabel ?? "Selected Address",
                  vehicle: {
                    'id': _selectedVehicleId ?? '',
                    'vehicle_type': _selectedVehicleType ?? 'SEDAN',
                    'brand_name': _selectedVehicleBrand ?? '',
                    'car_model': _selectedVehicleModel ?? '',
                    'license': _selectedVehicleLicense ?? '',
                  },
                  latitude: _latitude,
                  longitude: _longitude,
                ),
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0: // Vehicle
        return _selectedVehicleType != null;
      case 1: // Services
        return _selectedServiceIds.isNotEmpty;
      case 2: // Schedule
        return _selectedTime.isNotEmpty;
      case 3: // Address
        return _addressController.text.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            (_currentStep > 0 || Navigator.canPop(context))
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF01102B)),
                  onPressed: _previousStep,
                )
                : null,
        automaticallyImplyLeading: false,
        title: const Text(
          "Book Service",
          style: TextStyle(
            color: Color(0xFF01102B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stepper indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                _buildStepIndicator(0, Icons.directions_car, "Vehicle"),
                _buildStepLine(0),
                _buildStepIndicator(1, Icons.home_repair_service, "Services"),
                _buildStepLine(1),
                _buildStepIndicator(2, Icons.calendar_month, "Schedule"),
                _buildStepLine(2),
                _buildStepIndicator(3, Icons.location_on, "Address"),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildStepContent()),

          // Bottom Price Bar (only for Services step)
          if (_currentStep == 1)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Price",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Rs. ${_totalPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildPrimaryButton(
                    text: "Continue",
                    onTap: _canContinue() ? _nextStep : null,
                  ),
                ],
              ),
            )
          else if (_currentStep == 0)
            // Multi-Vehicle Continue
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: buildPrimaryButton(
                text: "Continue with ${_selectedVehicleIds.length} Vehicles",
                onTap: _selectedVehicleIds.isNotEmpty ? _nextStep : null,
              ),
            )
          else
            // Continue button for other steps (Schedule, Address)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: buildPrimaryButton(
                text: _currentStep == 3 ? "Review Summary" : "Continue",
                onTap: _canContinue() ? _nextStep : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, IconData icon, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                isActive || isCompleted
                    ? const Color(0xFF01102B)
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive || isCompleted ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF01102B) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? const Color(0xFF01102B) : Colors.grey[300],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildVehicleSelection();
      case 1:
        return _buildServicesSelection();
      case 2:
        return _buildTimeSelection();
      case 3:
        return _buildAddressSelection();
      default:
        return Container();
    }
  }

  Widget _buildVehicleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Your Vehicle",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01102B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose from your saved vehicles or add a new one",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Loading state
          if (_isLoadingVehicles)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          // Show saved vehicles
          else if (_savedVehicles.isNotEmpty)
            ..._savedVehicles.map((vehicle) {
              final isSelected = _selectedVehicleIds.contains(vehicle['id']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedVehicleIds.remove(vehicle['id']);
                      if (_selectedVehicleIds.isEmpty) {
                        _selectedVehicleId = null;
                        _selectedVehicleType = null;
                      }
                    } else {
                      _selectedVehicleIds.add(vehicle['id']);
                      // First selected becomes the primary for backward compatibility
                      _selectedVehicleId ??= vehicle['id'];
                      _selectedVehicleType ??= vehicle['vehicle_type'];
                      _selectedVehicleBrand = vehicle['brand_name'];
                      _selectedVehicleModel = vehicle['car_model'];
                      _selectedVehicleLicense = vehicle['license'];
                    }
                    
                    // Refresh services to get pricing (using the first selected as reference for UI list)
                    if (_selectedVehicleType != null) {
                      _isLoadingServices = true;
                      _fetchServices();
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFF01102B)
                              : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 60,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          _getVehicleImage(vehicle['vehicle_type']),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_car,
                              color: Color(0xFF01102B),
                              size: 32,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle['car_model'] != null &&
                                      vehicle['car_model'].toString().isNotEmpty
                                  ? vehicle['car_model'] // Show model if available
                                  : (vehicle['name'] ?? 'Vehicle'), 
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF01102B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtitle: Brand • Type • License (masked)
                            Text(
                              [
                                    vehicle['brand_name'],
                                    vehicle['vehicle_type'],
                                    if (vehicle['license'] != null &&
                                        vehicle['license']
                                            .toString()
                                            .isNotEmpty)
                                      "•••• ${vehicle['license'].toString().substring(vehicle['license'].toString().length > 4 ? vehicle['license'].toString().length - 4 : 0)}",
                                  ]
                                  .where(
                                    (e) => e != null && e.toString().isNotEmpty,
                                  )
                                  .join(" • "),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF01102B),
                          size: 28,
                        ),
                    ],
                  ),
                ),
              );
            })
          // Empty state
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No vehicles saved yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first vehicle to get started",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Button to add new vehicle
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Navigate to SelectVehicleScreen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectVehicleScreen(),
                  ),
                );

                // Refresh vehicles list after adding
                if (result != null) {
                  await _fetchVehicles();
                  // Auto-select the newly added vehicle
                  if (result is Map<String, dynamic>) {
                    // Result from select screen might be dynamic map
                    setState(() {
                      _selectedVehicleId = result['id']; // ID from insert result
                      _selectedVehicleId = result['id'];
                      _selectedVehicleType = result['vehicle_type'];
                      _selectedVehicleBrand = result['brand_name'];
                      _selectedVehicleModel = result['car_model'];
                      _selectedVehicleLicense = result['license'];
                      // Automatically move to next step
                      _currentStep = 1;
                    });
                  }
                }
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                "Add New Vehicle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01102B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleImage(String type) {
    if (type.toLowerCase().contains('sedan')) {
      return 'assets/Sedan.png';
    } else if (type.toLowerCase().contains('suv') ||
        type.toLowerCase().contains('muv')) {
      return 'assets/SUV.png';
    } else if (type.toLowerCase().contains('hatchback')) {
      return 'assets/hatchback.png';
    }
    return 'assets/Sedan.png';
  }

  Widget _buildServicesSelection() {
    return _isLoadingServices
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF01102B)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Choose Services",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01102B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Select the services you want for your vehicle",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_availableServices.isEmpty)
                  const Center(child: Text("No services available right now")),
                ..._availableServices.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildServiceTile(
                      title: s['name'],
                      icon: s['icon'],
                      price: s['price'].toDouble(),
                      checklist: _getChecklistForService(s['name']),
                      categoryBadge: _getCategoryBadgeForVehicle(),
                      isSelected: _selectedServiceIds.contains(s['id']),
                      onTap: () => setState(() {
                        _selectedServiceIds.contains(s['id'])
                            ? _selectedServiceIds.remove(s['id'])
                            : _selectedServiceIds.add(s['id']);
                      }),
                    ),
                  );
                }),
              ],
            ),
          );
  }

  Widget _buildTimeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Schedule",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01102B),
            ),
          ),
          const SizedBox(height: 24),

          // Date label with Calendar Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Date",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF01102B),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF01102B),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF01102B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _rowStartDate =
                          picked; // Update the start of the list view
                    });
                    _fetchSlotData();
                  }
                },
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF01102B),
                ),
                tooltip: "Pick a date",
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable date selector
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  14, // Increased range to show 2 weeks from selected date
              itemBuilder: (context, index) {
                // List starts from the _selectedDate (or user picked date)
                // If user hasn't picked, _selectedDate is initially DateTime.now()
                // However, we want the *start* of the list to be the selected date?
                // The user requirement says: "below date scroll should start from that selected date"
                // So if I pick "Nov 20", the list should show "Nov 20, Nov 21, ..."

                // Careful: if I pick a date, I want that to be the first item?
                // Or do I want to maintain the "selected" logic?
                // "date scroll should start from that selected date" implies the first item (index 0)
                // should be the selected date.

                // Since the list starts FROM the selected date, the first item (index 0) is always selected by default logic
                // unless we change selection logic.
                // Actually, if I pick a date from calendar, that becomes _selectedDate.
                // If the list starts from _selectedDate, then index 0 is _selectedDate.
                // But if I tap index 1 (tomorrow relative to start), _selectedDate updates?
                // If _selectedDate updates, the whole list shifts? That might be jarring.

                // Improved logic:
                // We likely want a "startDate" for the list view, and a "_selectedDate" for the highlight.
                // BUT, the request says "scroll should start from that selected date".
                // Let's interpret this as: picking a date from calendar SETS the start of the list to that date,
                // AND selects it.

                // For this request, I will introduce `_viewStartDate` or just reuse `_rowStartDate` if it exists (it does in line 29! but wasn used).
                // Let's check line 29: `DateTime _rowStartDate = DateTime.now();`
                // Yes! I should use that.

                final dateForCell = _rowStartDate.add(Duration(days: index));
                final isSelected =
                    DateFormat('yyyy-MM-dd').format(_selectedDate) ==
                    DateFormat('yyyy-MM-dd').format(dateForCell);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = dateForCell;
                    });
                    _fetchSlotData();
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF01102B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF01102B)
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(dateForCell).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d').format(dateForCell),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF01102B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Time label
          const Text(
            "Time",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF01102B),
            ),
          ),
          const SizedBox(height: 12),

          // Time slots grid — 15-min intervals 6:00 AM to 9:00 PM
          // Past slots are greyed out; unavailable slots are shown greyed (not hidden)
          _isLoadingSlots ? const Center(child: CircularProgressIndicator()) : Builder(builder: (context) {
            if (_activeWorkers.isEmpty) {
               return Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.red[50],
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.red[200]!),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.info_outline, color: Colors.red[700]),
                     const SizedBox(width: 12),
                     const Expanded(child: Text("Sorry, there are no active workers available today.", style: TextStyle(color: Colors.red))),
                   ],
                 ),
               );
            }
            
            final now = DateTime.now();
            final isToday = _selectedDate.year == now.year &&
                _selectedDate.month == now.month &&
                _selectedDate.day == now.day;

            // Generate all slots: 6:00 AM (360 min) to 9:00 PM (1260 min) in 15-min steps
            final List<String> allSlots = [];
            for (int totalMin = 360; totalMin <= 1260; totalMin += 15) {
              final h = totalMin ~/ 60;
              final m = totalMin % 60;
              final period = h < 12 ? 'AM' : 'PM';
              final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
              allSlots.add(
                '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period',
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: allSlots.map((time) {
                final isSelected = _selectedTime == time;

                // Determine if slot is in the past (only relevant for today)
                bool isPast = false;
                final parts = time.split(RegExp(r'[: ]'));
                int h = int.parse(parts[0]);
                final m = int.parse(parts[1]);
                final isPM = parts[2] == 'PM';
                if (isPM && h != 12) h += 12;
                if (!isPM && h == 12) h = 0;
                
                if (isToday) {
                  final slotMinutes = h * 60 + m;
                  final nowMinutes = now.hour * 60 + now.minute;
                  isPast = slotMinutes <= nowMinutes;
                }
                
                final slotStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, h, m);
                final slotEnd = slotStart.add(const Duration(hours: 1)); // 1 hour wash duration

                // Evaluate overlap against ALL active workers
                int availableWorkers = 0;
                for (var worker in _activeWorkers) {
                   bool workerFree = true;
                   for (var b in _dayBookings) {
                      if (b['worker_id'] == worker['id']) {
                         if (b['scheduled_at'] == null) continue;
                         final bStart = DateTime.parse(b['scheduled_at']).toLocal();
                         final bEnd = bStart.add(const Duration(hours: 1));
                         if (bStart.isBefore(slotEnd) && bEnd.isAfter(slotStart)) {
                            workerFree = false;
                            break;
                         }
                      }
                   }
                   if (workerFree) availableWorkers++;
                }

                final isDisabled = isPast || availableWorkers <= 0;

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => setState(() => _selectedTime = time),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 64) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF01102B)
                          : isDisabled
                              ? Colors.grey[100]
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF01102B)
                            : isDisabled
                                ? Colors.grey[200]!
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isDisabled
                                  ? Colors.grey[400]
                                  : const Color(0xFF01102B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressLabel = "Current";
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Widget _buildAddressSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Location",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01102B),
            ),
          ),
          const SizedBox(height: 24),

          // Address Input with Autocomplete
          RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _addressController,
            focusNode: FocusNode(), // Create internal focus node
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (_savedAddresses.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              // Suggest last 4 addresses, filtering by text if needed, or just showing all recent
              // If text is empty, show recent 4.
              // If text is not empty, filter? The user said "show previously stored... in dropdown".
              // Usually implies suggestions.
              // Let's filter if text exists, otherwise show all (up to 4).
              return _savedAddresses
                  .where((addr) {
                    return addr['address'].toString().toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  })
                  .take(4);
            },
            displayStringForOption:
                (Map<String, dynamic> option) => _formatAddress(option),
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onEditingComplete,
            ) {
              return Column(
                children: [
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (value) => setState(() {}),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Selected Address",
                      hintText: "Enter address or select...",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFF01102B),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF01102B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width -
                        40, // Match parent width
                    color: Colors.white,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          leading: const Icon(
                            Icons.history,
                            size: 20,
                            color: Colors.grey,
                          ),
                          title: Text(option['address_type'] ?? 'Address'),
                          subtitle: Text(
                            _formatAddress(option),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _addressLabel = option['address_type'];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (Map<String, dynamic> selection) {
              // Update state is handled by controller update, but we might want to set label
              setState(() {
                _addressLabel = selection['label'];
              });
            },
          ),

          const SizedBox(height: 12),

          // Save Address Button logic (optional, keep if valid)
          if (_addressLabel == "New Address" ||
              (_addressLabel == null && _addressController.text.isNotEmpty))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  if (_addressController.text.isNotEmpty) {
                    String? label = await showDialog<String>(
                      context: context,
                      builder:
                          (context) => SimpleDialog(
                            title: const Text("Save as"),
                            children:
                                ['Home', 'Work', 'Other']
                                    .map(
                                      (l) => SimpleDialogOption(
                                        onPressed:
                                            () => Navigator.pop(context, l),
                                        child: Text(l),
                                      ),
                                    )
                                    .toList(),
                          ),
                    );
                    if (label != null) {
                      final user = MockDatabase.instance.auth.currentUser;
                      if (user != null) {
                        // For simplicity, we just save the current text as street if manually typed
                        // Ideally we show the refinement sheet, but let's just insert a flat record for now
                        await MockDatabase.instance.client
                            .from('addresses')
                            .insert({
                              'user_id': user['id'],
                              'address_type': label,
                              'street': _addressController.text,
                              'city': 'Unknown',
                              'state': 'Unknown',
                              'pincode': '000000',
                            })
                            .build<void>();
                        await _fetchAddresses();
                        setState(() {
                          _addressLabel = label;
                        });
                      }
                    }
                  }
                },
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text("Save this address"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF01102B),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Use current location option
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    "Use my current location",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
