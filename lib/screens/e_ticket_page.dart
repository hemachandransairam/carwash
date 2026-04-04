import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ETicketPage extends StatelessWidget {
  final String? bookingId;
  final String? qrToken;
  final Map<String, String> vehicle;
  final List<String> selectedServices;
  final DateTime selectedDate;
  final String selectedTime;
  final String addressLabel;
  final String addressText;
  final double totalPrice;
  final Map<String, dynamic>? worker;

  const ETicketPage({
    super.key,
    this.bookingId,
    this.qrToken,
    required this.vehicle,
    required this.selectedServices,
    required this.selectedDate,
    required this.selectedTime,
    required this.addressLabel,
    required this.addressText,
    required this.totalPrice,
    this.worker,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFBDBDBD,
      ), // Dimmable background like the image
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Main Ticket Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            // Celebratory Icon
                            const Text("🎉", style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            const Text(
                              "Thank You!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF01102B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Your order has been placed\nsuccessfully",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dashed Divider Alternative
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color:
                                        index % 2 == 0
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Ticket Content
                            _buildInfoGrid(),

                            const SizedBox(height: 20),

                            // Handled By Section
                            const Text(
                              "YOUR ORDER WILL BE HANDLED BY",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildWorkerCard(),

                            const SizedBox(height: 20),

                            // Footer Dashed line
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color:
                                        index % 2 == 0
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // QR Section
                            _buildQRSection(context),
                          ],
                        ),
                      ),
                    ),

                    // Side Cutouts (Circles)
                    Positioned(
                      left: -15,
                      top: 180, // Approximate position
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -15,
                      top: 180,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBDBDBD),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              buildPrimaryButton(
                text: "Continue",
                onTap: () {
                  // Navigate to Home screen and clear the stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _generateAndSavePDF(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF01102B), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      "Download Full Ticket (PDF)",
                      style: TextStyle(
                        color: Color(0xFF01102B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "CAR DETAILS",
              vehicle['model'] != null && vehicle['model']!.isNotEmpty
                  ? vehicle['model']!
                  : vehicle['name'] ?? 'Car',
              flex: 3,
            ),
            _buildInfoItem(
              "CAR TYPE",
              vehicle['type'] ?? 'Sedan',
              flex: 1,
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "SERVICES",
              selectedServices.join('\n'), // Dynamic Services
              flex: 3,
            ),
            _buildInfoItem(
              "LOCATION",
              addressText,
              flex: 1,
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "DATE & TIME",
              "${DateFormat('d MMM yyyy').format(selectedDate)} - $selectedTime",
              flex: 3,
            ),
            _buildInfoItem(
              "AMOUNT",
              "Rs. ${totalPrice.toStringAsFixed(0)}",
              flex: 1,
              align: CrossAxisAlignment.end,
              subtitle: "(incl tax)",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    int flex = 1,
    CrossAxisAlignment align = CrossAxisAlignment.start,
    String? subtitle,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF01102B),
              height: 1.4,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            backgroundImage: worker?['profile_pic'] != null ? NetworkImage(worker!['profile_pic']) : null,
            child: worker?['profile_pic'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker?['name'] ?? "Tom Holland", // Fallback for mock/preview
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  worker?['phone'] ?? "WinkWash Team",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQRData({bool urlEncoded = true}) {
    final Map<String, dynamic> data = {
      'booking_id': bookingId ?? "N/A",
      'qr_token': qrToken ?? "N/A",
    };
    final jsonStr = jsonEncode(data);
    return urlEncoded ? Uri.encodeComponent(jsonStr) : jsonStr;
  }

  Widget _buildQRSection(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${_getQRData()}", 
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.error, color: Colors.red),
              ),
            ),
            GestureDetector(
              onTap: () => _downloadQR(context),
              child: const Text(
                "Download QR",
                style: TextStyle(
                  color: Color(0xFF3498DB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline, // Add underline for link-feel
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: Text(
            "Show this QR to our Team member!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF01102B),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadQR(BuildContext context) async {
    final qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${_getQRData()}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Saving to Gallery...",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    try {
      // 1. Download the image bytes
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode != 200) throw Exception("Failed to fetch image");

      // 2. Save byte data to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/wink_wash_qr_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);

      // 3. Save to gallery using 'gal' package
      // On modern platforms this handles permission internally or requests if needed
      await Gal.putImage(tempPath);

      // 4. Cleanup temp file
      await file.delete();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Successfully saved to your Gallery!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save to gallery: $e"),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _generateAndSavePDF(BuildContext context) async {
    final pdf = pw.Document();
    final qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${_getQRData()}";
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      final response = await http.get(Uri.parse(qrImageUrl));
      final qrImage = pw.MemoryImage(response.bodyBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("WinkWash", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text("E-Ticket & Receipt", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(qrImage),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),
                  pw.Text("BOOKING DETAILS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 12),
                  _buildPdfRow("Booking ID", bookingId ?? "N/A"),
                  _buildPdfRow("Schedule", "${DateFormat('EEE, d MMM yyyy').format(selectedDate)} • $selectedTime"),
                  _buildPdfRow("Service Location", addressText),
                  pw.SizedBox(height: 30),
                  pw.Text("VEHICLE INFORMATION", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 12),
                  _buildPdfRow("Vehicle", "${vehicle['brand']} ${vehicle['model']}"),
                  _buildPdfRow("Type", vehicle['type'] ?? "N/A"),
                  _buildPdfRow("License Plate", vehicle['license'] ?? "N/A"),
                  pw.SizedBox(height: 30),
                  pw.Text("SERVICES", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 12),
                  ...selectedServices.map((s) => pw.Bullet(text: s, style: const pw.TextStyle(fontSize: 12))),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Amount Paid", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Rs. $totalPrice", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Text("Thank you for choosing WinkWash!", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }
}
