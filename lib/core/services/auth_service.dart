import 'mock_database.dart';
import 'auth_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final MockAuth _auth = MockDatabase.instance.auth;
  final AuthApiService _api = AuthApiService();

  String? get currentUserPhone => _api.currentUserPhone ?? _auth.currentUser?['phone']?.toString();
  String? get userId => _api.userId ?? _auth.currentUser?['id']?.toString();

  Future<void> initUser() async {
    await _api.loadSession();
    await _auth.init();
  }

  Future<bool> checkPhone(String phone) async {
    return _api.checkPhone(phone);
  }

  Future<void> sendOtp(String phone) async {
    // Using the Edge Function for sending OTP as it holds the correct template name
    await _api.sendOtp(phone);
  }

  Future<Map<String, dynamic>> login(String phone, String otp) async {
    await _auth.verifyOtp(phone: phone, token: otp, type: null);
    return _auth.currentUser ?? {};
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String otp,
    String role = 'CUSTOMER',
  }) async {
    await _auth.verifyOtp(phone: phone, token: otp, type: null);
    // After verify, we might want to update the profile with name/email
    if (_auth.currentUser != null) {
      _auth.updateSessionUser({
        ..._auth.currentUser!,
        'name': name,
        'email': email,
        'role': role,
      });
    }
    return _auth.currentUser ?? {};
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
