import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildGlobalAppBar(context: context, title: "Settings"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Preferences"),
            _buildSwitchTile(
              "Notifications",
              "Receive updates on your bookings",
              _notificationsEnabled,
              (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSwitchTile(
              "Dark Mode",
              "Enable dark theme",
              _darkMode,
              (val) => setState(() => _darkMode = val),
            ),
            _buildSwitchTile(
              "Location Services",
              "Allow app to access location",
              _locationEnabled,
              (val) => setState(() => _locationEnabled = val),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader("Account"),
            _buildActionTile("Change Password", Icons.lock_outline, () {}),
            _buildActionTile(
              "Privacy Policy",
              Icons.privacy_tip_outlined,
              () {},
            ),
            _buildActionTile(
              "Terms of Service",
              Icons.description_outlined,
              () {},
            ),
            const SizedBox(height: 30),
            _buildSectionHeader("App Info"),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Version",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text("1.0.0"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF01102B),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF01102B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF01102B),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF01102B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF01102B), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF01102B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
