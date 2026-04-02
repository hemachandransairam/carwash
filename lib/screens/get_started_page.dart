import 'package:flutter/material.dart';
import '../auth/login.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isShortScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF01102B),
      body: Stack(
        children: [
          // Logo at top
          Positioned(
            top: padding.top + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/wynkwash_logo_white.png',
                width: size.width * 0.35,
              ),
            ),
          ),

          // Car Image in middle
          Positioned(
            top: size.height * (isShortScreen ? 0.22 : 0.25),
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/get_started.png',
              fit: BoxFit.contain,
              width: size.width,
            ),
          ),

          // Content at bottom
          Positioned(
            bottom: padding.bottom + (isShortScreen ? 40 : 60),
            left: 28,
            right: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your Journey to a\nGleaming Car Begin Here!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.075,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: isShortScreen ? 12 : 20),
                Text(
                  "Book a professional car wash in minutes and enjoy a spotless ride every time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isShortScreen ? 32 : 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF01102B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Let's Get Started",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
