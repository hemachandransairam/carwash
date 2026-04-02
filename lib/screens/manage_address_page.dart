import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_widgets.dart';

class ManageAddressPage extends StatefulWidget {
  const ManageAddressPage({super.key});

  @override
  State<ManageAddressPage> createState() => _ManageAddressPageState();
}

class _ManageAddressPageState extends State<ManageAddressPage> {
  final _addressController = TextEditingController();
  String _selectedLabel = 'Home';
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_addresses')
            .select()
            .eq('user_id', user.id);
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAddress() async {
    if (_addressController.text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('user_addresses').insert({
        'user_id': user.id,
        'label': _selectedLabel,
        'address': _addressController.text,
      });
      _addressController.clear();
      _fetchAddresses();
    }
  }

  Future<void> _deleteAddress(int id) async {
    await Supabase.instance.client.from('user_addresses').delete().eq('id', id);
    _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: buildGlobalAppBar(context: context, title: "Manage Address"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child:
                        _addresses.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No saved addresses",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _addresses.length,
                              itemBuilder: (context, index) {
                                final addr = _addresses[index];
                                return buildSavedAddressTile(
                                  label: addr['label'],
                                  address: addr['address'],
                                  isSelected: false,
                                  onTap: () {},
                                  onDelete: () => _deleteAddress(addr['id']),
                                );
                              },
                            ),
                  ),
                  _buildAddAddressSection(),
                ],
              ),
    );
  }

  Widget _buildAddAddressSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add New Address",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children:
                ['Home', 'Office', 'Other'].map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: buildLabelChip(
                      label: label,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedLabel = label),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          buildLocationInputField(
            controller: _addressController,
            hint: "Enter address details",
          ),
          const SizedBox(height: 24),
          buildPrimaryButton(text: "Add Address", onTap: _addAddress),
        ],
      ),
    );
  }
}
