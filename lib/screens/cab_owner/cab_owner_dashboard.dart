import 'package:flutter/material.dart';
import '../../core/services/mock_database.dart';
import '../../widgets/custom_widgets.dart';
import 'cab_vehicle_history_page.dart';
import 'cab_add_vehicle_page.dart';

class CabOwnerDashboard extends StatefulWidget {
  const CabOwnerDashboard({super.key});

  @override
  State<CabOwnerDashboard> createState() => _CabOwnerDashboardState();
}

class _CabOwnerDashboardState extends State<CabOwnerDashboard> {
  List<Map<String, dynamic>> _activeFleet = [];
  Map<String, Map<String, int>> _serviceSummary = {};
  bool _isLoading = true;
  String? _cabOwnerId;
  int _fleetLimit = 0; // set by admin in cab_owners.vehicle_count

  @override
  void initState() {
    super.initState();
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    setState(() => _isLoading = true);
    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;
      _cabOwnerId = user['id']?.toString();

      final vehicleRows = await MockDatabase.instance
          .from('vehicles')
          .select()
          .eq('user_id', _cabOwnerId!)
          .build<List<dynamic>>();

      final allVehicles = vehicleRows.map((v) => Map<String, dynamic>.from(v)).toList();
      final active = allVehicles;

      // Fetch fleet limit — graceful fallback if cab_owners not accessible
      int fleetLimit = 0;
      try {
        final cabRow = await MockDatabase.instance
            .from('cab_owners')
            .select('vehicle_count')
            .eq('user_id', _cabOwnerId!)
            .maybeSingle()
            .build<Map<String, dynamic>?>();
        fleetLimit = (cabRow?['vehicle_count'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      // Service summary — graceful fallback per vehicle
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toUtc().toIso8601String();
      final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

      Map<String, Map<String, int>> summary = {};
      for (final v in active) {
        try {
          final vid = v['id'].toString();
          final day = await MockDatabase.instance.from('bookings').select('id')
              .eq('vehicle_id', vid).gte('scheduled_at', todayStart).eq('status', 'COMPLETED')
              .build<List<dynamic>>();
          final week = await MockDatabase.instance.from('bookings').select('id')
              .eq('vehicle_id', vid).gte('scheduled_at', weekStartStr).eq('status', 'COMPLETED')
              .build<List<dynamic>>();
          final month = await MockDatabase.instance.from('bookings').select('id')
              .eq('vehicle_id', vid).gte('scheduled_at', monthStart).eq('status', 'COMPLETED')
              .build<List<dynamic>>();
          summary[vid] = {'day': day.length, 'week': week.length, 'month': month.length};
        } catch (_) {
          summary[v['id'].toString()] = {'day': 0, 'week': 0, 'month': 0};
        }
      }

      if (mounted) {
        setState(() {
          _activeFleet = active;
          _fleetLimit = fleetLimit;
          _serviceSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard _loadFleet error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(
        context: context,
        title: "Fleet Dashboard",
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _loadFleet,
            icon: const Icon(Icons.refresh, color: Color(0xFF01102B)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_fleetLimit > 0 && _activeFleet.length >= _fleetLimit) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fleet limit of $_fleetLimit vehicles reached. Contact admin to increase.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CabAddVehiclePage()),
          );
          if (result == true) _loadFleet();
        },
        backgroundColor: const Color(0xFF01102B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _fleetLimit > 0 ? 'Add Vehicle (${_activeFleet.length}/$_fleetLimit)' : 'Add Vehicle',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF01102B)))
          : _activeFleet.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFleet,
                  color: const Color(0xFF01102B),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildSummaryHeader(),
                      const SizedBox(height: 20),
                      const Text('Your Fleet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
                      const SizedBox(height: 12),
                      ..._activeFleet.map((v) => _buildVehicleCard(v)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryHeader() {
    final totalToday = _serviceSummary.values.fold(0, (s, m) => s + (m['day'] ?? 0));
    final totalMonth = _serviceSummary.values.fold(0, (s, m) => s + (m['month'] ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF01102B), Color(0xFF2A4371)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF01102B).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip("Fleet Size", "${_activeFleet.length}", Icons.directions_car),
          _buildStatDivider(),
          _buildStatChip("Today", "$totalToday", Icons.today),
          _buildStatDivider(),
          _buildStatChip("This Month", "$totalMonth", Icons.calendar_month),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 40, color: Colors.white24);

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final vid = vehicle['id'].toString();
    final summary = _serviceSummary[vid] ?? {'day': 0, 'week': 0, 'month': 0};
    final brand = vehicle['brand_name'] ?? '';
    final model = vehicle['car_model'] ?? '';
    final license = vehicle['license'] ?? 'N/A';
    final type = vehicle['vehicle_type'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CabVehicleHistoryPage(
            vehicleId: vid,
            vehicleName: '$brand $model',
            licensePlate: license,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01102B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_taxi, color: Color(0xFF01102B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$brand $model',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF01102B))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildBadge(license, Colors.grey.shade100, Colors.grey.shade700),
                          const SizedBox(width: 6),
                          if (type.isNotEmpty)
                            _buildBadge(type.replaceAll('_', ' '),
                                const Color(0xFF01102B).withValues(alpha: 0.08), const Color(0xFF01102B)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("Today", "${summary['day']}"),
                _buildMiniStatDivider(),
                _buildMiniStat("This Week", "${summary['week']}"),
                _buildMiniStatDivider(),
                _buildMiniStat("This Month", "${summary['month']}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMiniStatDivider() => Container(width: 1, height: 28, color: const Color(0xFFF0F0F0));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_taxi_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No vehicles added yet',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap "Add Vehicle" to register your fleet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
