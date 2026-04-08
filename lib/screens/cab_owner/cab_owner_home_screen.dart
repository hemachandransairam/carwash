import 'package:flutter/material.dart';
import 'cab_owner_dashboard.dart';
import 'cab_owner_book_page.dart';
import '../booking_history_page.dart';
import '../profile_page.dart';

class CabOwnerHomeScreen extends StatefulWidget {
  const CabOwnerHomeScreen({super.key});

  @override
  State<CabOwnerHomeScreen> createState() => _CabOwnerHomeScreenState();
}

class _CabOwnerHomeScreenState extends State<CabOwnerHomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      CabOwnerDashboard(),
      CabOwnerBookPage(),
      BookingHistoryPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, "Fleet"),
                _buildNavItem(1, Icons.add_circle_rounded, Icons.add_circle_outline, "Book"),
                _buildNavItem(2, Icons.access_time_filled, Icons.access_time, "History"),
                _buildNavItem(3, Icons.person, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF01102B) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF01102B).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            if (isSelected) const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF01102B) : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
