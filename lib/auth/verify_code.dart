import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/auth_service.dart';
import 'complete_profile.dart';
import '../screens/home_screen.dart';
import 'dart:async';

class VerifyCodePage extends StatefulWidget {
  final String phoneNumber;
  final bool isSignUp;
  const VerifyCodePage({super.key, required this.phoneNumber, this.isSignUp = false});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLocked = false;

  // Resend countdown
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account temporarily locked. Please wait 15 minutes."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isSignUp) {
        // Register the new user
        await AuthService().register(
          name: '',
          email: '',
          phone: widget.phoneNumber,
          otp: otp,
          role: 'CUSTOMER',
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
            (route) => false,
          );
        }
      } else {
        // Login existing user
        final user = await AuthService().login(widget.phoneNumber, otp);
        
        if (mounted) {
          final isProfileComplete = user['name'] != null && user['name'].toString().isNotEmpty;
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => isProfileComplete ? const HomeScreen() : const CompleteProfilePage(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          setState(() => _isLocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Maximum attempts reached. Please try again in 15 minutes."), backgroundColor: Colors.redAccent, duration: Duration(seconds: 4)),
          );
          Timer(const Duration(minutes: 15), () {
            if (mounted) setState(() { _isLocked = false; _failedAttempts = 0; });
          });
        } else {
          String msg = e.toString().replaceFirst('Exception: ', '');
          if (msg.startsWith('{')) {
            try {
              final decoded = jsonDecode(msg) as Map<String, dynamic>;
              msg = decoded['error']?.toString() ?? msg;
            } catch (_) {}
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid OTP: $msg. Attempts remaining: ${5 - _failedAttempts}"), backgroundColor: Colors.redAccent),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000814)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 10 : 20),
              const Text(
                "Verify Code",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter the code we just sent to\n${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
              SizedBox(height: isSmallScreen ? 30 : 60),

              // OTP Input Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => _otpBox(context, index),
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "Didn't receive OTP?",
                style: TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: (_isLoading || _resendCountdown > 0 || _isLocked) ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    await AuthService().sendOtp(widget.phoneNumber);
                    if (context.mounted) {
                      _startResendTimer();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP Resent")));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: Text(
                  _resendCountdown > 0
                      ? "Resend Code in ${_resendCountdown}s"
                      : "Resend Code",
                  style: TextStyle(
                    color: _resendCountdown > 0 ? Colors.grey : const Color(0xFF1D3557),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isLocked) ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked ? Colors.grey : const Color(0xFF000814),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                    : Text(
                        _isLocked ? "Locked" : "Verify OTP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return SizedBox(
      height: 60,
      width: 42,
      child: TextField(
        controller: _otpControllers[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.length == 1 && index < 5) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
          if (value.length == 1 && index == 5) _verifyOtp();
        },
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
