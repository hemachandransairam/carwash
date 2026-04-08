import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/mock_database.dart';
import '../../widgets/custom_widgets.dart';

class CabVehicleHistoryPage extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final String licensePlate;

  const CabVehicleHistoryPage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
  });

  @override
  State<CabVehicleHistoryPage> createState() => _CabVehicleHistoryPageState();
}

class _CabVehicleHistoryPageState extends State<CabVehicleHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all completed bookings for this vehicle
      final bookings = await MockDatabase.instance
          .from('bookings')
          .select('id, scheduled_at, status, total_price, worker_id, created_at')
          .eq('vehicle_id', widget.vehicleId)
          .order('scheduled_at', ascending: false)
          .build<List<dynamic>>();

      final List<Map<String, dynamic>> enriched = [];

      for (final b in bookings) {
        final booking = Map<String, dynamic>.from(b);

        // Fetch services for this booking
        final services = await MockDatabase.instance
            .from('booking_vehicle_services')
            .select('service_id')
            .eq('booking_id', booking['id'])
            .build<List<dynamic>>();

        // Fetch service names
        List<String> serviceNames = [];
        for (final s in services) {
          final svc = await MockDatabase.instance
              .from('services')
              .select('name')
              .eq('id', s['service_id'])
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          if (svc != null) serviceNames.add(svc['name'].toString());
        }

        // Fetch worker name
        String workerName = 'N/A';
        if (booking['worker_id'] != null) {
          final worker = await MockDatabase.instance
              .from('users')
              .select('name')
              .eq('id', booking['worker_id'])
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          if (worker != null) workerName = worker['name']?.toString() ?? 'N/A';
        }

        enriched.add({
          ...booking,
          'service_names': serviceNames,
          'worker_name': workerName,
        });
      }

      if (mounted) {
        setState(() {
          _history = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(
        context: context,
        title: widget.vehicleName,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh, color: Color(0xFF01102B)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // License plate header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_taxi, color: Color(0xFF01102B), size: 20),
                const SizedBox(width: 10),
                Text(
                  widget.licensePlate,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
                ),
                const Spacer(),
                Text(
                  '${_history.length} service${_history.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF01102B)))
                : _history.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFF01102B),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _history.length,
                          itemBuilder: (_, i) => _buildHistoryCard(_history[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toUpperCase();
    final scheduledAt = booking['scheduled_at'] != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(DateTime.parse(booking['scheduled_at']).toLocal())
        : 'N/A';
    final services = (booking['service_names'] as List<String>).join(', ');
    final workerName = booking['worker_name'] ?? 'N/A';
    final cost = booking['total_price'];

    final statusColor = status == 'COMPLETED'
        ? Colors.green
        : status == 'CANCELLED'
            ? Colors.red
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  services.isNotEmpty ? services : 'Service',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF01102B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.calendar_today_outlined, scheduledAt),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.person_outline, 'Worker: $workerName'),
          if (cost != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.currency_rupee, '₹${cost.toString()}', bold: true),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: bold ? const Color(0xFF01102B) : Colors.grey[700],
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No service history yet", style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
