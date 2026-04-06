import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';

class SelectVehicleScreen extends StatefulWidget {
  const SelectVehicleScreen({super.key});

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, String>> filteredBrands = [];
  String? selectedBrand; // Re-added
  String? selectedCarType; // Re-added

  @override
  void initState() {
    super.initState();
    filteredBrands = brands;
    searchController.addListener(_filterBrands);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterBrands() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBrands =
          brands.where((brand) {
            return brand['name']!.toLowerCase().contains(query);
          }).toList();
    });
  }

  final List<Map<String, String>> brands = [
    {'name': 'BMW', 'logo': 'assets/bmw.png'},
    {'name': 'Audi', 'logo': 'assets/audi.png'},
    {'name': 'Mercedes', 'logo': 'assets/mercedes.png'},
    {'name': 'Toyota', 'logo': 'assets/toyota.png'},
    {'name': 'Honda', 'logo': 'assets/honda.png'},
    {'name': 'Ford', 'logo': 'assets/ford.png'},
    {'name': 'Hyundai', 'logo': 'assets/hyundai.png'},
    {'name': 'Kia', 'logo': 'assets/kia.png'},
    {'name': 'Suzuki', 'logo': 'assets/suzuki.png'},
    {'name': 'Tata', 'logo': 'assets/tata.png'},
    {'name': 'Mahindra', 'logo': 'assets/mahindra.png'},
    {'name': 'MG', 'logo': 'assets/mg.png'},
    {'name': 'Volkswagen', 'logo': 'assets/vw.png'},
    {'name': 'Renault', 'logo': 'assets/renault.png'},
    {'name': 'Nissan', 'logo': 'assets/nissan.png'},
    {'name': 'Skoda', 'logo': 'assets/skoda.png'},
    {'name': 'Volvo', 'logo': 'assets/volvo.png'},
    {'name': 'Jaguar', 'logo': 'assets/jaguar.png'},
    {'name': 'Lamborghini', 'logo': 'assets/lamborghini.png'},
  ];

  // Car types list
  final List<Map<String, String>> carTypes = [
    {'name': 'Sedan', 'image': 'assets/Sedan.png'},
    {'name': 'SUV or MUV', 'image': 'assets/SUV.png'},
    {'name': 'Hatchback', 'image': 'assets/hatchback.png'},
  ];

  String? selectedModel;
  String? licenseNumber;
  int? selectedSeats = 5;

  void _showCarDetailsPopup() {
    // Reset fields when opening
    TextEditingController modelController = TextEditingController(
      text: selectedModel,
    );
    TextEditingController licenseController = TextEditingController(
      text: licenseNumber,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Provide additional details (optional)',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Model Input
                      Text(
                        "Car Model(optional)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: modelController,
                        decoration: InputDecoration(
                          hintText: "e.g. Swift, City, X5",
                          filled: true,
                          fillColor: const Color(0xFFF6F6F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // License Input
                      Text(
                        "License Number(optional)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: licenseController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: "e.g. KA 02 AB 1234",
                          filled: true,
                          fillColor: const Color(0xFFF6F6F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        "Seating Capacity",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedSeats = 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedSeats == 5 ? const Color(0xFF01102B) : const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text('5 Seater', style: TextStyle(color: selectedSeats == 5 ? Colors.white : Colors.grey[800], fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedSeats = 7),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedSeats == 7 ? const Color(0xFF01102B) : const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text('7+ Seater', style: TextStyle(color: selectedSeats == 7 ? Colors.white : Colors.grey[800], fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedModel = modelController.text.trim();
                              licenseNumber = licenseController.text.trim();
                            });
                            Navigator.pop(context); // Close details popup
                            _showCarTypePopup(); // Open type popup
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01102B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCarTypePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select Your Car Type', // Removed '?' as requested
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children:
                            carTypes.map((type) {
                              final isTypeSelected =
                                  selectedCarType == type['name'];
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedCarType = type['name'];
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          isTypeSelected
                                              ? const Color(0xFF3498DB)
                                              : const Color(0xFFEEEEEE),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border:
                                              isTypeSelected
                                                  ? Border.all(
                                                    color: const Color(
                                                      0xFF3498DB,
                                                    ),
                                                    width: 1,
                                                  )
                                                  : null,
                                        ),
                                        child: Image.asset(
                                          type['image']!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          type['name']!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              selectedCarType == null
                                  ? null
                                  : () async {
                                    try {
                                      // Show loading
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (context) => const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                      );

                                      // Get current user
                                      final user =
                                          MockDatabase
                                              .instance
                                              .auth
                                              .currentUser;

                                      if (user != null) {
                                        // Save vehicle to MockDatabase and get back the autogenerated ID
                                        final newVehicle = await MockDatabase.instance.client
                                            .from('vehicles')
                                            .insert({
                                              'user_id': user['id'],
                                              'brand_name': selectedBrand,
                                              'vehicle_type': selectedCarType,
                                              'seat_count': selectedSeats ?? 5,
                                              'car_model': selectedModel,
                                              'license': licenseNumber,
                                              'created_at': DateTime.now().toUtc().toIso8601String(),
                                            })
                                            .select()
                                            .maybeSingle()
                                            .build<Map<String, dynamic>?>();
                                        
                                        String? createdId;
                                        if (newVehicle != null) {
                                          createdId = newVehicle['id']?.toString();
                                        }

                                        // Close loading dialog
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }

                                        // Close car type dialog
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }

                                        // Return to booking page with data including ID
                                        if (context.mounted) {
                                          Navigator.pop(context, {
                                            'id': createdId,
                                            'brand_name': selectedBrand,
                                            'vehicle_type': selectedCarType,
                                            'car_model': selectedModel,
                                            'license': licenseNumber,
                                            'seat_count': selectedSeats ?? 5,
                                          });
                                        }
                                      } // End if (user != null)
                                    } catch (e) {
                                      // Close loading dialog if error
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }

                                      // Show error message
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error saving vehicle: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01102B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Proceed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF01102B),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Select Vehicle',
          style: TextStyle(
            color: Color(0xFF01102B),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        // Removed actions as requested
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Brands',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF01102B),
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Brand",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    filteredBrands.isEmpty
                        ? Center(
                          child: Text(
                            "No brands found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                        : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: size.width > 400 ? 1.3 : 1.1,
                              ),
                          itemCount: filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = filteredBrands[index];
                            final isSelected = selectedBrand == brand['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedBrand = brand['name'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xFF01102B,
                                          ).withValues(alpha: 0.05)
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF01102B)
                                            : Colors.grey.withValues(alpha: 0.1),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.asset(
                                  brand['logo']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        brand['name']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF01102B),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    selectedBrand == null ? null : () => _showCarDetailsPopup(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01102B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
