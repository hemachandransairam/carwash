import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../screens/location_permission_screen.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _handleCompleteProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = MockDatabase.instance.auth.currentUser;
      if (user == null) return;

      final result = await MockDatabase.instance.from('users').upsert({
        if (user['id'] != null) 'id': user['id'],
        'name': name,
        'phone': user['phone'],
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'gender': _selectedGender,
        'gst_number': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        'date_of_birth': _selectedDob?.toIso8601String(),
        'role': 'USER',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select().maybeSingle().build<Map<String, dynamic>?>();

      if (result != null) {
        MockDatabase.instance.auth.updateSessionUser(result);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationPermissionScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 750;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000814)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Text(
                "Complete Your Profile",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Don't worry, only you can see your personal\ndata. No one else can view it.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),

              // Profile Image Picker
              Stack(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 50 : 60,
                    backgroundColor: const Color(0xFFF0F0F0),
                    child: Icon(
                      Icons.person,
                      size: isSmallScreen ? 60 : 80,
                      color: const Color(0xFF000814),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF000814),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 20 : 32),

              _buildLabel("Name *"),
              _buildTextField(_nameController, "Ex. John Doe"),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildLabel("Phone Number *"),
              _buildPhoneField(),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildLabel("Email (Optional)"),
              _buildTextField(_emailController, "example@email.com",
                  keyboardType: TextInputType.emailAddress),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildLabel("Gender"),
              _buildGenderDropdown(),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildLabel("Date of Birth (Optional)"),
              _buildDobPicker(),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildLabel("GST Number (Optional)"),
              _buildTextField(_gstController, "e.g. 29ABCDE1234F1Z5"),
              SizedBox(height: isSmallScreen ? 12 : 16),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCompleteProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000814),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Complete Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF000814)),
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    return GestureDetector(
      onTap: _pickDob,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Text(
          _selectedDob == null
              ? 'Select date of birth'
              : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
          style: TextStyle(
            fontSize: 14,
            color: _selectedDob == null
                ? Colors.grey.withValues(alpha: 0.5)
                : const Color(0xFF000814),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    // Phone is locked — taken from the login session, not editable
    final user = MockDatabase.instance.auth.currentUser;
    final phone = user?['phone']?.toString() ?? '';

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(
            phone.isNotEmpty ? '+$phone' : 'Not available',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: const Text("Select", style: TextStyle(color: Colors.grey, fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: ["Male", "Female", "Other"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedGender = newValue),
        ),
      ),
    );
  }
}
