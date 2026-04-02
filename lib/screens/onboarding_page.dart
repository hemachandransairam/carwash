import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'get_started_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/ob1.png',
      'title': 'Car Wash at Your\nDoorstep',
      'description':
          'Book a professional car wash and our trained staff will come straight to your home — no travel, no waiting.',
    },
    {
      'image': 'assets/ob2.png',
      'title': 'Professional\nCleaning, Every Time',
      'description':
          'From foam wash to detailed cleaning, we use the right tools and techniques to give your car the care it deserves.',
    },
    {
      'image': 'assets/ob3.png',
      'title': 'Because Your Car\nDeserves Better',
      'description':
          'Your car looks brand new — a quick rating helps us keep delivering top-quality service.',
    },
  ];

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_shown', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GetStartedPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFFD9EFFF),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingContent(
                image: _pages[index]['image']!,
                title: _pages[index]['title']!,
                description: _pages[index]['description']!,
              );
            },
          ),
          Positioned(
            bottom: padding.bottom + 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _onNext,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF01102B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF01102B) : const Color(0xFFD1D1D1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingContent({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // TOP HALF - Takes 50% height
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              image,
              // Setting specific dimensions to maintain quality
              width: 485,
              height: 600,
              fit:
                  BoxFit
                      .contain, // Ensures the 485x448 image doesn't get cut off
            ),
          ),
        ),

        // BOTTOM HALF - Content Section
        Expanded(
          flex: 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(250, 100),
                    topRight: Radius.elliptical(250, 100),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 80, 40, 20),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF01102B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -40,
                left: (size.width / 2) - 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF01102B),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/W.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
