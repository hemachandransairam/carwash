import 'package:flutter/material.dart';
import '../../core/services/mock_database.dart';

class CabOwnerSetupPage extends StatefulWidget {
  const CabOwnerSetupPage({super.key});

  @override
  State<CabOwnerSetupPage> createState() => _CabOwnerSetupPageState();
}

class _CabOwnerSetupPageState extends State<CabOwnerSetupPage> {
  final _formKey = GlobalKey<FormState>();

  // Personal details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _altPhoneController = TextEditingController();

  // Business details
  final _companyNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isSaving = false;
  int _currentStep = 0; // 0 = personal, 1 = business

  @override
  void initState() {
    super.initState();
    _prefillFromSession();
  }

  void _prefillFromSession() {
    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) return;
    _nameController.text = user['name']?.toString() ?? '';
    _emailController.text = user['email']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _altPhoneController.dispose();
    _companyNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;

      // Update users table with personal + business details
      final updatedUser = await MockDatabase.instance.from('users').update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'company_name': _companyNameController.text.trim(),
        'gst_number': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        'cab_owner_profile_complete': true,
      }).eq('id', user['id']).select().maybeSingle().build<Map<String, dynamic>?>();

      // Upsert into cab_owners table
      await MockDatabase.instance.from('cab_owners').upsert({
        'user_id': user['id'],
        'company_name': _companyNameController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'pincode': _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        'alt_phone': _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
        'gst_number': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        'is_active': true,
      }).build();

      if (updatedUser != null) {
        MockDatabase.instance.auth.updateSessionUser(updatedUser);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MockDatabase.instance.auth.currentUser;
    final phone = user?['phone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF01102B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome to WynkWash',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Complete Your Profile',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  // Step indicator
                  Row(
                    children: [
                      _buildStepDot(0, 'Personal'),
                      Expanded(child: Container(height: 2, color: _currentStep > 0 ? Colors.white : Colors.white24)),
                      _buildStepDot(1, 'Business'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0
                      ? _buildPersonalStep(phone)
                      : _buildBusinessStep(),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF01102B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back',
                            style: TextStyle(color: Color(0xFF01102B), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () {
                        if (_formKey.currentState!.validate()) {
                          if (_currentStep == 0) {
                            setState(() => _currentStep = 1);
                          } else {
                            _submit();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01102B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 0 ? 'Next' : 'Complete Setup',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? Icon(step < _currentStep ? Icons.check : Icons.circle,
                    color: const Color(0xFF01102B), size: 16)
                : Text('${step + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildPersonalStep(String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        const SizedBox(height: 20),
        _buildField('Full Name *', _nameController, 'Enter your full name'),
        const SizedBox(height: 16),

        // Phone — locked
        _buildLabel('Phone Number'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 10),
              Text('+$phone', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildField('Alternate Phone', _altPhoneController, 'Optional',
            keyboardType: TextInputType.phone, required: false),
        const SizedBox(height: 16),
        _buildField('Email', _emailController, 'Optional',
            keyboardType: TextInputType.emailAddress, required: false),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF01102B))),
        const SizedBox(height: 20),
        _buildField('Company / Fleet Name *', _companyNameController, 'e.g. DD Taxi Services'),
        const SizedBox(height: 16),
        _buildField('GST Number', _gstController, 'Optional (e.g. 29ABCDE1234F1Z5)',
            required: false),
        const SizedBox(height: 16),
        _buildField('Business Address', _addressController, 'Street / Area',
            required: false),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildField('City', _cityController, 'e.g. Bangalore', required: false)),
            const SizedBox(width: 12),
            Expanded(child: _buildField('Pincode', _pincodeController, 'e.g. 560001',
                keyboardType: TextInputType.number, required: false)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF01102B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF01102B), size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'After setup, you can add your fleet vehicles from the dashboard.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF01102B)),
                ),
              ),
            ],
          ),
        ),
      ],
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
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null
              : null,
        ),
      ],
    );
  }
}
