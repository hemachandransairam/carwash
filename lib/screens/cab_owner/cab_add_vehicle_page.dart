import 'package:flutter/material.dart';
import '../../core/services/mock_database.dart';
import '../../widgets/custom_widgets.dart';

class CabAddVehiclePage extends StatefulWidget {
  const CabAddVehiclePage({super.key});

  @override
  State<CabAddVehiclePage> createState() => _CabAddVehiclePageState();
}

class _CabAddVehiclePageState extends State<CabAddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _licenseController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _seatsController = TextEditingController();

  String? _selectedVehicleType;
  bool _isSaving = false;

  static const List<String> _vehicleTypes = [
    'HATCHBACK',
    'SEDAN',
    'SMALL_SUV',
    'LARGE_SUV',
    'LUXURY',
    'MUV',
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _licenseController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;

      await MockDatabase.instance.from('vehicles').insert({
        'user_id': user['id'],
        'brand_name': _brandController.text.trim(),
        'car_model': _modelController.text.trim(),
        'vehicle_type': _selectedVehicleType,
        'license': _licenseController.text.trim().toUpperCase(),
        'color': _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        'year': _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text.trim()),
        'seat_count': int.tryParse(_seatsController.text.trim()) ?? 5,
        'status': 'ACTIVE',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).build();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added to your fleet.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add vehicle: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Add Vehicle"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF01102B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in your vehicle details. Admin will review and approve.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildField('Brand / Make *', _brandController, 'e.g. Toyota, Maruti, Hyundai'),
              const SizedBox(height: 16),
              _buildField('Model *', _modelController, 'e.g. Innova, Swift, Creta'),
              const SizedBox(height: 16),
              _buildField('License Plate Number *', _licenseController, 'e.g. KA01AB1234',
                  textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 16),

              // Vehicle type
              _buildLabel('Vehicle Type *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVehicleType,
                    isExpanded: true,
                    hint: const Text('Select type', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    items: _vehicleTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF01102B))),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedVehicleType = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildField('Color', _colorController, 'e.g. White'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Year', _yearController, 'e.g. 2020',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Seating Capacity *', _seatsController, 'e.g. 5 or 7',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: buildPrimaryButton(
                  text: _isSaving ? 'Submitting...' : 'Submit for Approval',
                  onTap: _isSaving ? null : _submit,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Admin will review and approve your vehicle.\nYou will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF01102B)));
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    final isRequired = label.endsWith('*');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF01102B)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null
              : null,
        ),
      ],
    );
  }
}
