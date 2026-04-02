import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data =
            await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('id', user.id)
                .single();
        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _userData = {'full_name': 'New User', 'email': user.email};
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final avatarSize = size.width * 0.25; // Increased from 0.2

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildGlobalAppBar(
        context: context,
        title: "Profile",
        titleColor: Colors.white, // Make title white
        showBackButton: false,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
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
              : Stack(
                children: [
                  // Background image extending to full screen including notch area
                  Positioned.fill(
                    child: Image.asset(
                      'assets/profile_background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  // Content
                  Column(
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            24,
                      ),
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
                                    color: Colors.black.withOpacity(0.05),
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
                        _userData?['full_name'] ?? "User Name",
                        style: const TextStyle(
                          fontSize: 24, // Increased from 20
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF01102B),
                        ),
                      ),
                      const SizedBox(height: 32), // Increased from 20
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
                ],
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
