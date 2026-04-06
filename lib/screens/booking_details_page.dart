import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/mock_database.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vehicleDetails = [];
  Map<String, dynamic>? _customerData;
  Map<String, dynamic>? _workerData;

  // Per-vehicle photos keyed by booking_vehicle_id (bv_id)
  final Map<String, List<String>> _beforePhotos = {};
  final Map<String, List<String>> _afterPhotos = {};

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      // 1. Fetch Customer Info
      final customer = await MockDatabase.instance
          .from('users')
          .select('name, phone')
          .eq('id', widget.booking['user_id'])
          .maybeSingle()
          .build<Map<String, dynamic>?>();

      // 2. Fetch Worker Info
      Map<String, dynamic>? worker;
      if (widget.booking['worker_id'] != null) {
        final workerId = widget.booking['worker_id'];
        final wRec = await MockDatabase.instance
            .from('workers')
            .select('user_id')
            .eq('id', workerId)
            .maybeSingle()
            .build<Map<String, dynamic>?>();
        if (wRec != null) {
          worker = await MockDatabase.instance
              .from('users')
              .select()
              .eq('id', wRec['user_id'])
              .maybeSingle()
              .build<Map<String, dynamic>?>();
        }
        worker ??= await MockDatabase.instance
            .from('users')
            .select()
            .eq('id', workerId)
            .maybeSingle()
            .build<Map<String, dynamic>?>();
      }

      // 3. Fetch all vehicles for this booking
      final vehicles = await MockDatabase.instance
          .from('booking_vehicles')
          .select()
          .eq('booking_id', widget.booking['id'])
          .build<List<Map<String, dynamic>>>();

      List<Map<String, dynamic>> details = [];

      for (var bv in vehicles) {
        final String bvId = bv['id'].toString();

        // Fetch Vehicle Info
        final vInfo = await MockDatabase.instance
            .from('vehicles')
            .select('brand_name, car_model, license')
            .eq('id', bv['vehicle_id'])
            .maybeSingle()
            .build<Map<String, dynamic>?>();

        // Fetch Services
        final services = await MockDatabase.instance
            .from('booking_vehicle_services')
            .select('service_id')
            .eq('booking_vehicle_id', bvId)
            .build<List<Map<String, dynamic>>>();

        List<String> serviceNames = [];
        for (var sRef in services) {
          final sInfo = await MockDatabase.instance
              .from('services')
              .select('name')
              .eq('id', sRef['service_id'])
              .maybeSingle()
              .build<Map<String, dynamic>?>();
          if (sInfo != null) serviceNames.add(sInfo['name']);
        }

        // 4. Fetch photos per vehicle from storage: before/{bvId}/ and after/{bvId}/
        List<String> beforeUrls = [];
        List<String> afterUrls = [];

        try {
          // DB: booking_images rows for this booking_vehicle_id
          final dbBefore = await MockDatabase.instance
              .from('booking_images')
              .select('image_url')
              .eq('booking_id', widget.booking['id'])
              .eq('booking_vehicle_id', bvId)
              .eq('image_type', 'BEFORE')
              .build<List<Map<String, dynamic>>>();
          beforeUrls.addAll(dbBefore.map((r) => r['image_url'] as String));

          final dbAfter = await MockDatabase.instance
              .from('booking_images')
              .select('image_url')
              .eq('booking_id', widget.booking['id'])
              .eq('booking_vehicle_id', bvId)
              .eq('image_type', 'AFTER')
              .build<List<Map<String, dynamic>>>();
          afterUrls.addAll(dbAfter.map((r) => r['image_url'] as String));
        } catch (_) {}

        // Storage: before/{bvId}/ — same path the worker app uploads to
        try {
          final beforeFiles = await MockDatabase.instance.client.storage
              .from('booking-images')
              .list(path: 'before/$bvId');
          for (final f in beforeFiles) {
            if (f.name == '.emptyFolderPlaceholder') continue;
            final url = MockDatabase.instance.client.storage
                .from('booking-images')
                .getPublicUrl('before/$bvId/${f.name}');
            if (!beforeUrls.contains(url)) beforeUrls.add(url);
          }
        } catch (_) {}

        try {
          final afterFiles = await MockDatabase.instance.client.storage
              .from('booking-images')
              .list(path: 'after/$bvId');
          for (final f in afterFiles) {
            if (f.name == '.emptyFolderPlaceholder') continue;
            final url = MockDatabase.instance.client.storage
                .from('booking-images')
                .getPublicUrl('after/$bvId/${f.name}');
            if (!afterUrls.contains(url)) afterUrls.add(url);
          }
        } catch (_) {}

        _beforePhotos[bvId] = beforeUrls;
        _afterPhotos[bvId] = afterUrls;

        details.add({
          'bv_id': bvId,
          'car_name': vInfo != null
              ? "${vInfo['brand_name']} ${vInfo['car_model']}"
              : "Unknown Car",
          'license': vInfo?['license'] ?? "N/A",
          'services': serviceNames,
        });
      }

      if (mounted) {
        setState(() {
          _customerData = customer;
          _workerData = worker;
          _vehicleDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.booking['status'] as String? ?? '').toUpperCase();
    final date = DateTime.parse(widget.booking['scheduled_at']).toLocal();
    final formattedDate = DateFormat('d/M/yyyy').format(date);
    final formattedTime = DateFormat('HH:mm').format(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF01102B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Booking Details",
          style: TextStyle(
            color: Color(0xFF01102B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(status, formattedDate, formattedTime),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildIdentityCard(
                          "Customer",
                          _customerData?['name'] ?? "User",
                          _customerData?['phone'] ?? "No Phone",
                          Icons.person,
                          _customerData?['avatar_url'],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIdentityCard(
                          "Technician",
                          _workerData?['name'] ?? "Not Assigned",
                          _workerData?['phone'] ?? "No Contact",
                          Icons.engineering,
                          _workerData?['avatar_url'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Service Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF01102B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Each vehicle card now includes its own before/after photos
                  ..._vehicleDetails.map((v) => _buildVehicleCard(v)),

                  const SizedBox(height: 32),
                  _buildPaymentDetails(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(String status, String date, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF01102B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ID",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking['id'].toString().substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfo(Icons.calendar_month_outlined, "Date", date),
              _buildHeaderInfo(Icons.access_time, "Time", time),
              _buildHeaderInfo(Icons.directions_car_outlined, "Type", "Sedan"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 24),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildIdentityCard(
      String label, String name, String sub, IconData icon,
      [String? imageUrl]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(icon, color: const Color(0xFF01102B), size: 18),
                    ),
                  )
                : Icon(icon, color: const Color(0xFF01102B), size: 18),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Vehicle card now includes before/after photos for that specific vehicle
  Widget _buildVehicleCard(Map<String, dynamic> v) {
    final bvId = v['bv_id'] as String;
    final beforePhotos = _beforePhotos[bvId] ?? [];
    final afterPhotos = _afterPhotos[bvId] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle header
          Row(
            children: [
              const Icon(Icons.directions_car_rounded,
                  color: Color(0xFF01102B), size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['car_name'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B))),
                  Text(v['license'],
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Services
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (v['services'] as List<String>)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF677294))),
                    ))
                .toList(),
          ),

          // Photos for this vehicle only
          if (beforePhotos.isNotEmpty || afterPhotos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            const Text(
              "Work Photos",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B)),
            ),
            const SizedBox(height: 12),
            _buildPhotoSection("Before", beforePhotos),
            const SizedBox(height: 12),
            _buildPhotoSection("After", afterPhotos),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String title, List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF677294))),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text("No photos available",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _showFullScreenImage(photos[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photos[index],
                    width: 140,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    final base = (widget.booking['base_amount'] ?? 0.0) as num;
    final discount = (widget.booking['discount_amount'] ?? 0.0) as num;
    final total = (widget.booking['final_amount'] ?? 0.0) as num;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Details",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF01102B))),
          const SizedBox(height: 20),
          _buildPriceRow("Base Service", "Rs. ${base.toStringAsFixed(2)}"),
          if (discount > 0)
            _buildPriceRow("Discount", "- Rs. ${discount.toStringAsFixed(2)}",
                isDiscount: true),
          const Divider(height: 32, color: Color(0xFFF0F0F0)),
          _buildPriceRow("Total Paid", "Rs. ${total.toStringAsFixed(2)}",
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal
                      ? const Color(0xFF01102B)
                      : Colors.grey[500],
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isTotal ? FontWeight.w800 : FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  color: isDiscount
                      ? Colors.green
                      : (isTotal
                          ? const Color(0xFF01102B)
                          : Colors.black87),
                  fontSize: isTotal ? 20 : 15,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}