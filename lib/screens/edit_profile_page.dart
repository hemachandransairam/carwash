import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = true;
  String? _addressId;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      try {
        final profile = await MockDatabase.instance.from('users').select().eq('id', user['id']).maybeSingle().build<Map<String, dynamic>?>();
        final address = await MockDatabase.instance.from('addresses').select().eq('user_id', user['id']).limit(1).maybeSingle().build<Map<String, dynamic>?>();
        
        if (mounted) {
          setState(() {
            _nameController.text = profile?['name'] ?? '';
            _emailController.text = profile?['email'] ?? '';
            _phoneController.text = profile?['phone'] ?? '';
            
            if (address != null) {
              _addressId = address['id'];
              _houseController.text = address['house_no'] ?? '';
              _streetController.text = address['street'] ?? '';
              _cityController.text = address['city'] ?? '';
            }
            
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update Profile
      await MockDatabase.instance.from('users').upsert({
        'id': user['id'],
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).build<void>();

      // 2. Update/Insert Address
      await MockDatabase.instance.from('addresses').upsert({
        if (_addressId != null) 'id': _addressId,
        'user_id': user['id'],
        'house_no': _houseController.text,
        'street': _streetController.text,
        'city': _cityController.text,
        'state': 'Manual', // Default
        'pincode': '000000', // Default
        'address_type': 'HOME',
        'is_default': true,
      }).build<void>();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildGlobalAppBar(context: context, title: "Edit Profile"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTextField(
                      "Full Name",
                      _nameController,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      "Email Address",
                      _emailController,
                      Icons.email_outlined,
                      isEmail: true,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      "Phone Number",
                      _phoneController,
                      Icons.phone_outlined,
                      isPhone: true,
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Location Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01102B))),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("House / Flat No.", _houseController, Icons.home_outlined),
                    const SizedBox(height: 20),
                    _buildTextField("Street / Area", _streetController, Icons.location_on_outlined),
                    const SizedBox(height: 20),
                    _buildTextField("City", _cityController, Icons.location_city_outlined),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF01102B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF01102B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType:
              isPhone
                  ? TextInputType.phone
                  : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF01102B), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
