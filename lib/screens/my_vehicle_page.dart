import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      try {
        final data = await MockDatabase.instance
            .from('vehicles')
            .select()
            .eq('user_id', user['id'])
            .build<List<Map<String, dynamic>>>();
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteVehicle(int id) async {
    await MockDatabase.instance.from('vehicles').delete().eq('id', id).build<void>();
    _fetchVehicles();
  }

  void _addVehicle() {
    String? selectedBrand;
    final brands = [
      {'name': 'BMW', 'logo': 'assets/bmw.png'},
      {'name': 'Ford', 'logo': 'assets/ford.png'},
      {'name': 'MG', 'logo': 'assets/mg.png'},
      {'name': 'Kia', 'logo': 'assets/kia.png'},
      {'name': 'Toyota', 'logo': 'assets/toyota.png'},
      {'name': 'Volkswagen', 'logo': 'assets/vw.png'},
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Brand",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 300,
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: brands.length,
                            itemBuilder: (context, index) {
                              final brand = brands[index];
                              final isSelected = selectedBrand == brand['name'];
                              return GestureDetector(
                                onTap:
                                    () => setDialogState(
                                      () => selectedBrand = brand['name'],
                                    ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? const Color(0xFF01102B)
                                              : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      brand['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildPrimaryButton(
                          text: "Next",
                          onTap:
                              selectedBrand == null
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                    _showTypeDialog(selectedBrand!);
                                  },
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showTypeDialog(String brand) {
    String? selectedType;
    final types = ['Sedan', 'SUV', 'Hatchback'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text("Select Type for $brand"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        types
                            .map(
                              (type) => ListTile(
                                title: Text(type),
                                leading: Radio<String>(
                                  value: type,
                                  groupValue: selectedType,
                                  onChanged:
                                      (v) => setDialogState(
                                        () => selectedType = v,
                                      ),
                                ),
                                onTap:
                                    () => setDialogState(
                                      () => selectedType = type,
                                    ),
                              ),
                            )
                            .toList(),
                  ),
                  actions: [
                    buildPrimaryButton(
                      text: "Add Vehicle",
                      onTap:
                          selectedType == null
                              ? null
                              : () async {
                                final user =
                                    MockDatabase.instance.auth.currentUser;
                                if (user != null) {
                                  await MockDatabase.instance
                                      .from('vehicles')
                                      .insert({
                                        'user_id': user['id'],
                                        'name': '$brand $selectedType',
                                        'brand': brand,
                                        'type': selectedType,
                                      })
                                      .build<void>();
                                  _fetchVehicles();
                                  if (mounted) Navigator.pop(context);
                                }
                              },
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "My Vehicles"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _vehicles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _vehicles.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: buildPrimaryButton(
                        text: "Add New Vehicle",
                        onTap: _addVehicle,
                      ),
                    );
                  }
                  final v = _vehicles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Color(0xFF01102B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['name'] ?? v['brand_name'] ?? 'Unnamed Vehicle',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${v['brand'] ?? v['brand_name'] ?? 'Unknown'} • ${v['type'] ?? v['vehicle_type'] ?? 'Unknown'}",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteVehicle(v['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
