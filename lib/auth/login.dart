import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/auth_service.dart';
import 'verify_code.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isFocused = false;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit WhatsApp number')),
      );
      return;
    }

    final apiPhone = '91$digits';
    setState(() => _isLoading = true);

    try {
      // O(1) check — is this phone in the workers DB?
      final exists = await AuthService().checkPhone(apiPhone);

      // Send OTP regardless (same screen, different destination after verify)
      await AuthService().sendOtp(apiPhone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => VerifyCodePage(
            phoneNumber: apiPhone,
            isSignUp: !exists, // passing this down
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.startsWith('{')) {
        try {
          final decoded = jsonDecode(msg) as Map<String, dynamic>;
          msg = decoded['error']?.toString() ?? msg;
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;
    final keyboardUp = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF01102B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/loginbg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF01102B)),
            ),
          ),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _isFocused ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              builder: (_, val, __) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * val, sigmaY: 8 * val),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(1, 16, 43, 0.5 + 0.3 * val),
                        const Color(0xFF01102B),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Column(
                      children: [
                        SizedBox(height: keyboardUp ? h * 0.01 : h * 0.06),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: keyboardUp ? w * 0.25 : w * 0.45,
                          child: Image.asset(
                            'assets/wynkwash_logo_white.png',
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.local_car_wash, color: Colors.white, size: 100),
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            alignment: _isFocused ? Alignment.center : Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Welcome',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: h * 0.038,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: h * 0.008),
                                Text(
                                  'Enter your WhatsApp number to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: h * 0.018,
                                  ),
                                ),
                                SizedBox(height: h * 0.04),
                                // Phone field
                                Container(
                                  height: h * 0.065,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF01102B).withAlpha(153),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: h * 0.02),
                                        child: Text(
                                          '+91',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: h * 0.019,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(width: 1, height: h * 0.03, color: Colors.white24),
                                      SizedBox(width: h * 0.015),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneController,
                                          focusNode: _focusNode,
                                          keyboardType: TextInputType.number,
                                          maxLength: 10,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: h * 0.019,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            hintText: 'Enter number',
                                            hintStyle: TextStyle(color: Colors.white24, fontSize: h * 0.016),
                                            counterText: '',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onSubmitted: (_) => _onNext(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: h * 0.05),
                                SizedBox(
                                  width: double.infinity,
                                  height: h * 0.065,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _onNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2A4371),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(h * 0.032),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: h * 0.03,
                                            width: h * 0.03,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Next',
                                            style: TextStyle(
                                              fontSize: h * 0.021,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(height: h * 0.04),
                                Padding(
                                  padding: EdgeInsets.only(bottom: h * 0.025),
                                  child: Text(
                                    'By continuing, you agree to the T&C and Privacy Policy',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white38, fontSize: h * 0.013),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
