import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/mock_database.dart';
import 'complete_profile.dart';
import '../screens/home_screen.dart';

class VerifyCodePage extends StatefulWidget {
  final String phoneNumber;
  const VerifyCodePage({super.key, required this.phoneNumber});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responseUser = await MockDatabase.instance.auth.verifyOtp(
        phone: widget.phoneNumber,
        token: otp,
        type: null,
      );

      final user = MockDatabase.instance.auth.currentUser;
      if (user != null) {
        // Successful login, now check if they are a new user
        
        // Let's check for a profile in 'profiles' table
        final Map<String, dynamic>? profile = await MockDatabase.instance
            .from('profiles')
            .select()
            .eq('id', user['id'])
            .maybeSingle()
            .build();

        if (mounted) {
          if (profile == null) {
            // New user, go to complete profile
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CompleteProfilePage()),
              (route) => false,
            );
          } else {
            // Old user, go home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
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
                onPressed: _isLoading ? null : () async {
                  await MockDatabase.instance.auth.signInWithOtp(phone: widget.phoneNumber);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP Resent")));
                  }
                },
                child: const Text(
                  "Resend Code",
                  style: TextStyle(
                    color: Color(0xFF1D3557),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000814),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(
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
      width: 45,
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
