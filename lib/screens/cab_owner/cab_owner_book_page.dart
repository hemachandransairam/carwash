import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/mock_database.dart';
import '../../widgets/custom_widgets.dart';

class CabOwnerBookPage extends StatefulWidget {
  const CabOwnerBookPage({super.key});

  @override
  State<CabOwnerBookPage> createState() => _CabOwnerBookPageState();
}

class _CabOwnerBookPageState extends State<CabOwnerBookPage> {
  // Step: 0=select vehicles, 1=select service, 2=date/time, 3=confirm
  int _step = 0;

  List<Map<String, dynamic>> _fleet = [];
  final Set<String> _selectedVehicleIds = {};
  bool _isLoadingFleet = true;

  List<Map<String, dynamic>> _services = [];
  String? _selectedServiceId;
  String? _selectedServiceName;
  bool _isLoadingServices = true;

  // Custom pricing: serviceId -> price (set by admin for this cab owner)
  Map<String, double> _customPricing = {};

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadFleetAndPricing();
  }

  Future<void> _loadFleetAndPricing() async {
    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;

      // Try vehicles table first (admin may have added vehicles directly)
      final vehicleRows = await MockDatabase.instance
          .from('vehicles')
          .select('id, brand_name, car_model, license, vehicle_type')
          .eq('user_id', user['id'])
          .build<List<dynamic>>();

      // Fallback: use cab_owners table license_number entries
      List<Map<String, dynamic>> fleet;
      if (vehicleRows.isNotEmpty) {
        fleet = vehicleRows.map((v) => Map<String, dynamic>.from(v)).toList();
      } else {
        final cabOwnerRows = await MockDatabase.instance
            .from('cab_owners')
            .select('id, license_number, company_name')
            .eq('user_id', user['id'])
            .build<List<dynamic>>();
        fleet = cabOwnerRows.map((v) => {
          'id': v['id'],
          'brand_name': v['company_name'] ?? 'Fleet Vehicle',
          'car_model': '',
          'license': v['license_number'] ?? 'N/A',
          'vehicle_type': '',
        }).toList();
      }

      // Load custom pricing (graceful fallback if table missing)
      Map<String, double> pricingMap = {};
      try {
        final pricing = await MockDatabase.instance
            .from('cab_owner_pricing')
            .select('service_id, price')
            .eq('user_id', user['id'])
            .build<List<dynamic>>();
        for (final p in pricing) {
          pricingMap[p['service_id'].toString()] = (p['price'] as num).toDouble();
        }
      } catch (_) {}

      // Load active services
      final services = await MockDatabase.instance
          .from('services')
          .select('id, name, base_price')
          .eq('is_active', true)
          .build<List<dynamic>>();

      if (mounted) {
        setState(() {
          _fleet = fleet;
          _customPricing = pricingMap;
          _services = services.map((s) => Map<String, dynamic>.from(s)).toList();
          _isLoadingFleet = false;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFleet = false;
          _isLoadingServices = false;
        });
      }
    }
  }

  double _priceFor(String serviceId) {
    // Custom pricing takes priority
    if (_customPricing.containsKey(serviceId)) return _customPricing[serviceId]!;
    // Fallback to base price
    final svc = _services.firstWhere((s) => s['id'].toString() == serviceId, orElse: () => {});
    return (svc['base_price'] as num?)?.toDouble() ?? 0.0;
  }

  double get _totalPrice {
    if (_selectedServiceId == null) return 0;
    return _selectedVehicleIds.length * _priceFor(_selectedServiceId!);
  }

  Future<void> _confirmBooking() async {
    if (_selectedVehicleIds.isEmpty || _selectedServiceId == null || _selectedTime.isEmpty) return;
    setState(() => _isBooking = true);

    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;

      // 1. Fetch all workers from the workers table
      final List<Map<String, dynamic>> workersResponse = await MockDatabase.instance.client
          .from('workers')
          .select()
          .build<List<Map<String, dynamic>>>();

      final List<Map<String, dynamic>> approvedWorkers = workersResponse.where((w) {
         final status = w['status']?.toString().toUpperCase() ?? '';
         return status == 'APPROVED' || status == 'ACTIVE';
      }).toList();

      final Set<String> assignedInCurrentTransaction = {};

      // Parse selected datetime
      final timeParts = _selectedTime.split(':');
      final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
      final scheduledAt = dt.toUtc().toIso8601String();
      final scheduledEndAt = dt.add(const Duration(hours: 1)).toUtc().toIso8601String();

      // Create one booking per vehicle
      for (final vehicleId in _selectedVehicleIds) {
        String? assignedWorkerId;

        // Try to find an available worker
        for (var worker in approvedWorkers) {
          final String workerTableId = worker['id'];
          final String? userId = worker['user_id'];

          if (assignedInCurrentTransaction.contains(workerTableId)) continue;
          if (userId == null) continue;

          // Confirm role
          final userDetails = await MockDatabase.instance.client
              .from('users')
              .select('id, name, role')
              .eq('id', userId)
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          
          if (userDetails == null) continue;
          final role = userDetails['role']?.toString().toUpperCase() ?? 'USER';
          
          // Relaxing role check slightly to include common technician roles
          if (role != 'WORKER' && role != 'WORKERS' && role != 'TECHNICIAN' && role != 'EMPLOYEE' && role != 'STAFF') {
            continue;
          }

          // Check for busy slots
          // Only CONFIRMED or IN_PROGRESS bookings at the SAME time should block
          final busyBookingsResp = await MockDatabase.instance.client
              .from('bookings')
              .select('scheduled_at, service_end, status')
              .eq('worker_id', workerTableId)
              .build<List<Map<String, dynamic>>>();
          
          bool isBusy = false;
          for (var b in busyBookingsResp) {
            final bStatus = (b['status'] ?? '').toString().toUpperCase();
            // Cancelled, rejected, or completed bookings do not block new ones
            if (bStatus == 'CANCELLED' || bStatus == 'REJECTED' || bStatus == 'COMPLETED') continue;

            if (b['scheduled_at'] == null) continue;
            final bStart = DateTime.parse(b['scheduled_at']);
            final bEnd = b['service_end'] != null ? DateTime.parse(b['service_end']) : bStart.add(const Duration(hours: 1));
            
            // Check for time overlap
            if (bStart.isBefore(dt.add(const Duration(hours: 1))) && bEnd.isAfter(dt)) {
              isBusy = true;
              break;
            }
          }

          if (!isBusy) {
            assignedWorkerId = workerTableId;
            assignedInCurrentTransaction.add(workerTableId);
            break;
          }
        }

        if (assignedWorkerId == null) {
          if (approvedWorkers.isEmpty) {
            throw Exception("No approved workers found in system. Please contact administrator.");
          }
          throw Exception("All our workers are currently busy or unavailable at this slot. Please try a different time.");
        }

        final bookingRes = await MockDatabase.instance
            .from('bookings')
            .insert({
              'user_id': user['id'],
              'vehicle_id': vehicleId,
              'vehicle_ids': [vehicleId],
              'service_id': [_selectedServiceId],
              'worker_id': assignedWorkerId,
              'booking_type': 'SCHEDULED',
              'scheduled_at': scheduledAt,
              'service_start': scheduledAt,
              'service_end': scheduledEndAt,
              'status': 'IN_PROGRESS',
              'base_amount': _priceFor(_selectedServiceId!),
              'discount_amount': 0.0,
              'final_amount': _priceFor(_selectedServiceId!),
              'total_price': _priceFor(_selectedServiceId!),
              'qr_token': 'QR-${DateTime.now().millisecondsSinceEpoch}',
              'is_cab_owner': true,
              'latitude': 0.0,
              'longitude': 0.0,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select('id')
            .build<List<dynamic>>();

        if (bookingRes.isNotEmpty) {
          final bookingId = bookingRes.first['id'];

          // Insert into booking_vehicles junction
          final bvRes = await MockDatabase.instance.client
              .from('booking_vehicles')
              .insert({'booking_id': bookingId, 'vehicle_id': vehicleId})
              .select('id')
              .single()
              .build<Map<String, dynamic>>();

          // Insert service for this vehicle
          await MockDatabase.instance.client
              .from('booking_vehicle_services')
              .insert({
                'booking_vehicle_id': bvRes['id'],
                'service_id': _selectedServiceId,
              })
              .build<dynamic>();
        }
      }

      if (mounted) {
        final bookedCount = _selectedVehicleIds.length;
        setState(() {
          _isBooking = false;
          _step = 0;
          _selectedVehicleIds.clear();
          _selectedServiceId = null;
          _selectedServiceName = null;
          _selectedTime = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bookedCount > 1 ? '$bookedCount bookings confirmed!' : 'Booking confirmed!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(
        context: context,
        title: "Book Service",
        showBackButton: false,
      ),
      body: _isLoadingFleet
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF01102B)))
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(child: _buildCurrentStep()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ["Vehicles", "Service", "Schedule", "Confirm"];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green
                            : isActive
                                ? const Color(0xFF01102B)
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? const Color(0xFF01102B) : Colors.grey,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone ? Colors.green : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildVehicleStep();
      case 1: return _buildServiceStep();
      case 2: return _buildScheduleStep();
      case 3: return _buildConfirmStep();
      default: return const SizedBox();
    }
  }

  // ── Step 0: Vehicle Selection ──────────────────────────────────────────────
  Widget _buildVehicleStep() {
    if (_fleet.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_taxi_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No fleet vehicles found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text("Contact admin to register your fleet.", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Select vehicles to service",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
        ),
        const SizedBox(height: 4),
        Text(
          "${_selectedVehicleIds.length} selected",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ..._fleet.map((v) {
          final vid = v['id'].toString();
          final isSelected = _selectedVehicleIds.contains(vid);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedVehicleIds.remove(vid);
              } else {
                _selectedVehicleIds.add(vid);
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF01102B).withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF01102B) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_taxi,
                    color: isSelected ? const Color(0xFF01102B) : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v['brand_name']} ${v['car_model']}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
                        ),
                        Text(
                          v['license'] ?? 'No plate',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF01102B), size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 1: Service Selection ──────────────────────────────────────────────
  Widget _buildServiceStep() {
    if (_isLoadingServices) return const Center(child: CircularProgressIndicator(color: Color(0xFF01102B)));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Select a service",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
        ),
        const SizedBox(height: 4),
        const Text("Custom pricing applied for your fleet.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        ..._services.map((svc) {
          final sid = svc['id'].toString();
          final isSelected = _selectedServiceId == sid;
          final price = _priceFor(sid);
          final hasCustom = _customPricing.containsKey(sid);

          return GestureDetector(
            onTap: () => setState(() {
              _selectedServiceId = sid;
              _selectedServiceName = svc['name'].toString();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF01102B).withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF01102B) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              svc['name'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
                            ),
                            if (hasCustom) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text("Custom", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${price.toStringAsFixed(0)} per vehicle',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        if (_selectedVehicleIds.isNotEmpty)
                          Text(
                            'Total: ₹${(price * _selectedVehicleIds.length).toStringAsFixed(0)} for ${_selectedVehicleIds.length} vehicle${_selectedVehicleIds.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF01102B), fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFF01102B), size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 2: Schedule ───────────────────────────────────────────────────────
  Widget _buildScheduleStep() {
    final now = DateTime.now();
    final slots = _generateSlots();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Select date", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B))),
        const SizedBox(height: 12),
        // Date row
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (_, i) {
              final date = now.add(Duration(days: i));
              final isSelected = _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _selectedTime = '';
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 10),
                  width: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF01102B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF01102B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text("Select time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedTime == slot;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF01102B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF01102B) : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF01102B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _generateSlots() {
    final slots = <String>[];
    for (int h = 6; h <= 21; h++) {
      for (int m = 0; m < 60; m += 15) {
        if (h == 21 && m > 0) break;
        slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  // ── Step 3: Confirm ────────────────────────────────────────────────────────
  Widget _buildConfirmStep() {
    final selectedVehicles = _fleet.where((v) => _selectedVehicleIds.contains(v['id'].toString())).toList();
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Booking Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        const SizedBox(height: 16),
        _buildSummaryCard(
          icon: Icons.local_car_wash,
          label: "Service",
          value: _selectedServiceName ?? '',
        ),
        _buildSummaryCard(
          icon: Icons.calendar_today,
          label: "Date & Time",
          value: '$formattedDate at $_selectedTime',
        ),
        _buildSummaryCard(
          icon: Icons.local_taxi,
          label: "Vehicles (${selectedVehicles.length})",
          value: selectedVehicles.map((v) => '${v['brand_name']} ${v['car_model']} (${v['license'] ?? 'No plate'})').join('\n'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF01102B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF01102B).withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B))),
              Text(
                '₹${_totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF01102B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "* Custom pricing applied. Worker assigned automatically.",
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF01102B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF01102B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final canProceed = switch (_step) {
      0 => _selectedVehicleIds.isNotEmpty,
      1 => _selectedServiceId != null,
      2 => _selectedTime.isNotEmpty,
      _ => true,
    };

    final isLastStep = _step == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF01102B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Back", style: TextStyle(color: Color(0xFF01102B), fontWeight: FontWeight.w700)),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () {
                      if (isLastStep) {
                        _confirmBooking();
                      } else {
                        setState(() => _step++);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01102B),
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isLastStep ? "Confirm Booking" : "Next",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
