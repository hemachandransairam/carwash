import 'package:flutter/material.dart';
import '../core/services/mock_database.dart';
import '../widgets/custom_widgets.dart';
import 'booking_history_page.dart';
import '../auth/login.dart';
import 'manage_address_page.dart';
import 'my_vehicle_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'help_center_page.dart';
import 'notification_page.dart';
import 'feedback_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user != null) {
      try {
        final data =
            await MockDatabase.instance
                .from('users')
                .select()
                .eq('id', user['id'])
                .maybeSingle()
                .build<Map<String, dynamic>?>();
        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _userData = {'name': 'New User', 'email': user['email'] ?? ''};
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    await MockDatabase.instance.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _updateMobileNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Mobile Number"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("To update your mobile number, verify the OTP sent to your new number.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter New Mobile Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile number updated successfully!")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01102B)),
            child: const Text("Send OTP", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _manageActiveDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manage Active Devices"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone_iphone, color: Colors.green),
              title: Text("This Device"),
              subtitle: Text("Active Now"),
            ),
            ListTile(
              leading: Icon(Icons.laptop),
              title: Text("Web Browser"),
              subtitle: Text("Last active 2 days ago"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _logout(); // Simulates global sign out across tokens
            },
            child: const Text("Log out of all devices", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final avatarSize = size.width * 0.25; // Increased from 0.2

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.white,
      appBar: buildGlobalAppBar(
        context: context,
        title: "Profile",
        titleColor: const Color(0xFF01102B),
        showBackButton: Navigator.canPop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF01102B),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                      // Avatar Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: avatarSize * 0.5,
                                  color: const Color(0xFF01102B),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF01102B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // Increased from 12
                      Text(
                        _userData?['name'] ?? "User Name",
                        style: const TextStyle(
                          fontSize: 24, // Increased from 20
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      const SizedBox(height: 32), // Increased from 20
                      // Apartment Plan Badge
                      if ((_userData?['is_apartment_resident'] == true ||
                          (_userData?['subscription_tier'] != null && _userData?['subscription_tier'] != 'NONE')))
                        _buildApartmentBadge(),
                      if ((_userData?['is_apartment_resident'] == true ||
                          (_userData?['subscription_tier'] != null && _userData?['subscription_tier'] != 'NONE')))
                        const SizedBox(height: 16),
                      // Menu Items
                      ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMenuItem(
                            context,
                            "Edit Profile",
                            icon: Icons.account_circle_outlined,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                              if (result == true) {
                                _fetchUserData();
                              }
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "My Bookings",
                            icon: Icons.history_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const BookingHistoryPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "Manage Address",
                            icon: Icons.location_on_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ManageAddressPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "My Vehicle",
                            icon: Icons.directions_car_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyVehiclesPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "Update Mobile Number",
                            icon: Icons.phone_android_outlined,
                            onTap: _updateMobileNumberDialog,
                          ),
                          _buildMenuItem(
                            context,
                            "Manage Active Devices",
                            icon: Icons.devices_other_outlined,
                            onTap: _manageActiveDevicesDialog,
                          ),
                          _buildMenuItem(
                            context,
                            "Feedback",
                            icon: Icons.rate_review_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeedbackPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "Settings",
                            icon: Icons.settings_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "Help Center",
                            icon: Icons.help_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpCenterPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            context,
                            "Logout",
                            icon: Icons.logout,
                            isLogout: true,
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ),
    );
  }

  Widget _buildApartmentBadge() {
    final aptName = _userData?['apartment_name']?.toString();
    final flat = _userData?['flat_number']?.toString();
    final block = _userData?['block']?.toString();
    final plan = _userData?['subscription_tier']?.toString();

    final subtitle = [
      if (block != null && block.isNotEmpty) 'Block $block',
      if (flat != null && flat.isNotEmpty) 'Flat $flat',
      if (plan != null && plan.isNotEmpty) plan,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF01102B), Color(0xFF1A3A6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF01102B).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aptName != null && aptName.isNotEmpty
                        ? aptName
                        : 'Apartment Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title, {
    IconData? icon,
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color:
                        isLogout ? Colors.redAccent : const Color(0xFF01102B),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isLogout ? Colors.redAccent : const Color(0xFF01102B),
                    ),
                  ),
                ),
                if (!isLogout)
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
      ],
    );
  }
}
