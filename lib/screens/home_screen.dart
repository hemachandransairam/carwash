import 'package:flutter/material.dart';
import 'dart:async';
import '../core/services/mock_database.dart';
import 'book_services_page.dart';
import 'booking_history_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'e_ticket_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const BookServicesPage(),
      const BookingHistoryPage(),
      const ProfilePage(),
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
              color: Colors.black.withOpacity(0.08), // Increased opacity
              blurRadius: 25, // Increased blur
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ), // Increased padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  "Home",
                ),
                _buildNavItem(
                  1,
                  Icons.description,
                  Icons.description_outlined,
                  "Book",
                ),
                _buildNavItem(
                  2,
                  Icons.access_time_filled,
                  Icons.access_time,
                  "History",
                ),
                _buildNavItem(3, Icons.person, Icons.person_outline, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65, // Increased width slightly
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
                color:
                    isSelected ? const Color(0xFF01102B) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF01102B,
                            ).withOpacity(0.4), // Increased opacity
                            blurRadius: 12, // Increased blur
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color:
                    isSelected
                        ? Colors.white
                        : Colors.grey[600], // Darker grey for unselected
                size: 28, // Increased size
              ),
            ),
            if (isSelected) const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF01102B)
                        : Colors.grey[600], // Darker grey for unselected
                fontSize: 12, // Increased font size
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const int _infinitePageCount = 10000;
  late final PageController _pageController;
  int _currentBannerPage = 0;
  Timer? _carouselTimer;
  // _isLoading is used for cancel action indication
  bool _isLoading = false;
  late final Stream<List<Map<String, dynamic>>> _activeOrderStream;

  String _currentAddress = "Select Location";

  final List<Map<String, dynamic>> _banners = [
    {
      'colors': [const Color(0xFFFDC830), const Color(0xFFF37335)],
      'title': 'CARWASH SERVICE',
      'subtitle': 'AT YOUR\nPLACE!',
    },
    {
      'colors': [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
      'title': 'QUICK SERVICE',
      'subtitle': 'SAVE YOUR\nTIME!',
    },
  ];

  // Static variable to track if address selection has been shown in this session
  static bool _hasShownAddressSelection = false;

  @override
  void initState() {
    super.initState();
    final user = MockDatabase.instance.auth.currentUser;
    _activeOrderStream = MockDatabase.instance
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', user?['id'] ?? '')
        .order('created_at', ascending: false)
        .limit(5) as Stream<List<Map<String, dynamic>>>;

    // Start at a large index in the middle for circular scrolling simulation
    _currentBannerPage = _infinitePageCount ~/ 2;
    _pageController = PageController(initialPage: _currentBannerPage);

    _carouselTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (_pageController.hasClients) {
        _currentBannerPage++;
        _pageController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownAddressSelection) {
        _showAddressSelection();
        _hasShownAddressSelection = true;
      }
    });
  }

  // _fetchActiveBooking is removed as we use StreamBuilder

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Future method to show address selection bottom sheet
  void _showAddressSelection() async {
    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) return;

    // Fetch recent addresses from the addresses table instead of bookings
    final response = await MockDatabase.instance
        .from('addresses')
        .select('house_no, street, city')
        .eq('user_id', user['id'])
        .order('created_at', ascending: false)
        .limit(5)
        .build<List<Map<String, dynamic>>>();

    final List<String> recentAddresses = [];
    for (var r in response) {
      final addr = "${r['house_no'] ?? ''} ${r['street'] ?? r['city'] ?? ''}".trim();
      if (addr.isNotEmpty && !recentAddresses.contains(addr)) {
        recentAddresses.add(addr);
      }
    }

    if (!mounted) return;

    showBarModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    final TextEditingController addressController =
                        TextEditingController();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Location",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (recentAddresses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("No recent addresses found."),
                          ),
                        ...recentAddresses.map(
                          (addr) => ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: Colors.grey,
                            ),
                            title: Text(addr),
                            onTap: () {
                              setState(() => _currentAddress = addr);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Add New Address",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: addressController,
                                decoration: InputDecoration(
                                  hintText: "Enter address",
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF01102B),
                                    ),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setState(
                                      () => _currentAddress = value.trim(),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                if (addressController.text.trim().isNotEmpty) {
                                  setState(
                                    () =>
                                        _currentAddress =
                                            addressController.text.trim(),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF01102B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.my_location,
                            color: Color(0xFF01102B),
                          ),
                          title: const Text(
                            "Use Current Location",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            setState(
                              () => _currentAddress = "Current Location",
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.06;
    final bool isShortScreen = size.height < 700;
    final double headerHeight = size.height * (isShortScreen ? 0.25 : 0.28);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: headerHeight,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/home_title.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.065,
                left: horizontalPadding,
                right: horizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            FutureBuilder<Map<String, dynamic>?>(
                              future:
                                  MockDatabase.instance
                                      .from('users')
                                      .select('name')
                                      .eq('id', MockDatabase.instance.auth.currentUser?['id'] ?? '')
                                      .maybeSingle()
                                      .build<Map<String, dynamic>?>(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final name =
                                      snapshot.data?['name'] as String? ??
                                      'User';
                                  return Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width * 0.08,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  );
                                }
                                return Text(
                                  'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size.width * 0.08,
                                    fontWeight: FontWeight.w900,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to Notification Page
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
                      ],
                    ),
                    SizedBox(height: size.height * 0.035),
                    const Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showAddressSelection,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              size.width * 0.5, // Limit to half screen width
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _currentAddress.length > 25
                                    ? '${_currentAddress.substring(0, 25)}...'
                                    : _currentAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Banner Carousel Section
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentBannerPage = page;
                });
              },
              itemBuilder: (context, index) {
                final banner = _banners[index % _banners.length];
                return _buildBanner(
                  horizontalPadding,
                  size,
                  banner['colors'],
                  banner['title'],
                  banner['subtitle'],
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildIndicator(index),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Book Service Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Booking Tab (Index 1)
                  final homeState =
                      context.findAncestorStateOfType<_HomeScreenState>();
                  if (homeState != null) {
                    homeState.setState(() => homeState._selectedIndex = 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01102B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF01102B).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.calendar_month, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Book a Service",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active Orders Section
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _activeOrderStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final allBookings = snapshot.data ?? [];
              Map<String, dynamic>? activeBooking;

              if (allBookings.isNotEmpty) {
                activeBooking = allBookings.firstWhere(
                  (b) {
                    final status = (b['status'] as String? ?? '').toUpperCase();
                    return status == 'ASSIGNED' || status == 'CONFIRMED' || status == 'PENDING';
                  },
                  orElse: () => {},
                );
                if (activeBooking.isEmpty) activeBooking = null;
              }

              if (activeBooking == null) {
                return const SizedBox.shrink();
              }
              
              // Helper to get formatted date
              String formatDateTime(String? iso) {
                if (iso == null) return "N/A";
                final dt = DateTime.parse(iso).toLocal();
                return DateFormat('EEE, d MMM • h:mm a').format(dt);
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF01102B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _navigateToTicket(activeBooking!),
                      child: Container(
                      width: double.infinity,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future: MockDatabase.instance
                                          .from('vehicles')
                                          .select('brand_name, car_model, vehicle_type')
                                          .eq('id', activeBooking['vehicle_id'] ?? '')
                                          .maybeSingle()
                                          .build<Map<String, dynamic>?>(),
                                      builder: (context, vSnap) {
                                        final car = vSnap.data;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              car != null 
                                                ? "${car['brand_name']} ${car['car_model']}"
                                                : "Fetching Car...",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF01102B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Text(
                                              car?['vehicle_type'] ?? '...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (activeBooking['status'].toString().toUpperCase() == 'PENDING')
                                          ? const Color(0xFFFFF4E5)
                                          : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (activeBooking['status'] as String)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        (activeBooking['status'].toString().toUpperCase() == 'PENDING')
                                            ? const Color(0xFFFF9800)
                                            : const Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDateTime(activeBooking['scheduled_at']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF01102B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: MockDatabase.instance.client
                                  .from('addresses')
                                  .select('house_no, street, city')
                                  .eq('user_id', activeBooking['user_id'] ?? '')
                                  .limit(1)
                                  .maybeSingle()
                                  .build<Map<String, dynamic>?>(),
                                builder: (context, aSnap) {
                                  final addr = aSnap.data;
                                  final addrText = addr != null 
                                    ? [addr['house_no'], addr['street'], addr['city']].where((e) => e != null && e.toString().isNotEmpty).join(", ")
                                    : "Fetching location...";
                                  return Expanded(
                                    child: Text(
                                      addrText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Price",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Rs. ${activeBooking['final_amount'] ?? activeBooking['base_amount'] ?? '0'}",
                                style: const TextStyle(
                                  color: Color(0xFF01102B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : ElevatedButton(
                                      onPressed:
                                          () => _showCancelDialog(
                                            activeBooking!['id'],
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF01102B,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel Order",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            },
          ),

          const SizedBox(height: 28),

          // Recent History Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const Text(
              'Recent History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF01102B),
              ),
            ),
          ),
          const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
            stream: _activeOrderStream,
            builder: (context, snapshot) {
              final allBookings = snapshot.data ?? [];
              final recentBookings = allBookings.where((b) {
                final status = (b['status'] as String? ?? '').toUpperCase();
                return status == 'COMPLETED' || status == 'CANCELLED';
              }).take(3).toList();

              if (recentBookings.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
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
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Recent History',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: recentBookings.map((booking) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                    child: GestureDetector(
                      onTap: () => _navigateToTicket(booking),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_car, color: Color(0xFF01102B), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: MockDatabase.instance.from('vehicles').select('brand_name, car_model').eq('id', booking['vehicle_id'] ?? '').maybeSingle().build<Map<String, dynamic>?>(),
                                    builder: (context, vSnap) {
                                      final car = vSnap.data;
                                      return Text(
                                        car != null ? "${car['brand_name']} ${car['car_model']}" : "Car Details",
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      );
                                    }
                                  ),
                                  Text(
                                    DateFormat('d MMM yyyy').format(DateTime.parse(booking['scheduled_at'])),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Rs. ${booking['final_amount']}",
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF01102B)),
                                ),
                                Text(
                                  booking['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: booking['status'].toString().toUpperCase() == 'COMPLETED' ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _navigateToTicket(Map<String, dynamic> booking) async {
    // 1. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // 2. Fetch all related data
      final vehicle = await MockDatabase.instance.from('vehicles').select().eq('id', booking['vehicle_id']).maybeSingle().build<Map<String, dynamic>?>();
      final address = await MockDatabase.instance.from('addresses').select().eq('user_id', booking['user_id']).limit(1).maybeSingle().build<Map<String, dynamic>?>();
      
      Map<String, dynamic>? worker;
      if (booking['worker_id'] != null) {
        final workerRec = await MockDatabase.instance.from('workers').select('user_id').eq('id', booking['worker_id']).maybeSingle().build<Map<String, dynamic>?>();
        if (workerRec != null) {
          worker = await MockDatabase.instance.from('users').select().eq('id', workerRec['user_id']).maybeSingle().build<Map<String, dynamic>?>();
        }
      }

      // 3. Map services back to names (simulated mapping)
      final List<String> serviceNames = (booking['service_id'] as List).map((id) {
        // Deterministic reverse mapping for mock
        if (id.toString().contains('b')) return 'Exterior Wash';
        if (id.toString().contains('c')) return 'Interior Cleaning';
        return 'Full Car Wash';
      }).toList();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ETicketPage(
            bookingId: booking['id'],
            qrToken: booking['qr_token'],
            vehicle: {
              'type': vehicle?['vehicle_type'] ?? 'Car',
              'brand': vehicle?['brand_name'] ?? 'Car',
              'model': vehicle?['car_model'] ?? 'N/A',
              'license': vehicle?['license'] ?? 'N/A',
            },
            selectedServices: serviceNames,
            selectedDate: DateTime.parse(booking['scheduled_at']),
            selectedTime: DateFormat('h:mm a').format(DateTime.parse(booking['scheduled_at'])),
            addressLabel: 'Service Location',
            addressText: address != null ? "${address['house_no']} ${address['street']}, ${address['city']}" : "N/A",
            totalPrice: (booking['final_amount'] ?? 0).toDouble(),
            worker: worker,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _showCancelDialog(String bookingId) async {
    final messenger = ScaffoldMessenger.of(context);
    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Cancel Order?"),
            content: const Text(
              "Are you sure you want to cancel this order? This action cannot be undone.",
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "No, Keep it",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close dialog
                  // Show loading
                  setState(() => _isLoading = true);
                  try {
                    await MockDatabase.instance.client
                        .from('bookings')
                        .update({'status': 'CANCELLED'})
                        .eq('id', bookingId)
                        .build<void>();

                    if (mounted) {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Order cancelled successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Error cancelling order: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "Yes, Cancel",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBanner(
    double padding,
    Size size,
    List<Color> colors,
    String tag,
    String title,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFF01102B),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF01102B),
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -15,
              bottom: 0,
              top: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.55),
                child: Image.asset('assets/home_car.png', fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color:
            (_currentBannerPage % _banners.length) == index
                ? const Color(0xFF01102B)
                : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF01102B),
        ),
      ),
    );
  }
}
