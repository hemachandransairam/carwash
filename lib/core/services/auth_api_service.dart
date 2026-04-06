import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/supabase_config.dart';

/// Auth via Supabase Edge Functions.
class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyUserId      = 'auth_user_id';
  static const _keyRole        = 'auth_role';
  static const _keyPhone       = 'auth_phone';
  static const _keyWorkerId    = 'auth_worker_id';

  String? _accessToken;
  String? _userId;
  String? _role;
  String? _phone;
  String? _workerId;

  String? get accessToken      => _accessToken;
  String? get userId           => _userId;
  String? get role             => _role;
  String? get currentUserPhone => _phone;
  String? get workerId         => _workerId;
  bool   get isLoggedIn        => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _userId      = prefs.getString(_keyUserId);
    _role        = prefs.getString(_keyRole);
    _phone       = prefs.getString(_keyPhone);
    _workerId    = prefs.getString(_keyWorkerId);
  }

  Future<void> _persistSession({
    required String accessToken,
    required String userId,
    required String role,
    required String phone,
  }) async {
    _accessToken = accessToken;
    _userId      = userId;
    _role        = role;
    _phone       = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyPhone, phone);
  }

  Future<void> clearSession() async {
    _accessToken = _userId = _role = _phone = _workerId = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_keyAccessToken, _keyUserId, _keyRole, _keyPhone, _keyWorkerId]) {
      await prefs.remove(k);
    }
  }

  Future<void> persistWorkerId(String workerId) async {
    _workerId = workerId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWorkerId, workerId);
  }

  // Adjust headers to match edge function requirements
  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    'apikey': SupabaseConfig.anonKey,
    if ((token ?? _accessToken) != null && (token ?? _accessToken)!.isNotEmpty)
      'Authorization': 'Bearer ${token ?? _accessToken}'
    else 
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}', // Fallback to anonkey for anon reqs
  };

  static bool _ok(int s) => s >= 200 && s < 300;

  String _normalizePhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length == 10 ? '91$d' : d;
  }

  /// POST /functions/v1/check-phone
  Future<bool> checkPhone(String phone) async {
    final res = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/check-phone'),
      headers: _headers(),
      body: jsonEncode({'phone': _normalizePhone(phone)}),
    );
    if (!_ok(res.statusCode)) {
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(data['error']?.toString() ?? res.body);
      } catch (_) {
        throw Exception(res.body.isNotEmpty ? res.body : 'Phone check failed');
      }
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['exists'] as bool? ?? false;
  }

  /// POST /functions/v1/send-otp
  Future<void> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/send-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': _normalizePhone(phone)}),
    );
    if (!_ok(res.statusCode)) throw Exception(res.body.isNotEmpty ? res.body : 'Failed to send OTP');
  }

  /// POST /functions/v1/verify-otp  (login)
  Future<Map<String, dynamic>> login(String phone, String otp) async {
    final normalized = _normalizePhone(phone);
    final res = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/verify-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': normalized, 'otp': otp, 'mode': 'login'}),
    );
    if (!_ok(res.statusCode)) throw Exception(res.body.isNotEmpty ? res.body : 'Login failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _persistSession(
      accessToken: data['access_token'] as String? ?? '',
      userId:      data['user_id']      as String? ?? '',
      role:        data['role']         as String? ?? 'CUSTOMER', // Changed from worker to customer
      phone:       normalized,
    );
    if (data['worker_id'] != null && data['worker_id'].toString().isNotEmpty) {
      await persistWorkerId(data['worker_id'].toString());
    }
    return data;
  }

  /// POST /functions/v1/verify-otp  (register)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String otp,
    String role = 'CUSTOMER', // Adjust for Customer app
  }) async {
    final normalized = _normalizePhone(phone);
    final res = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/verify-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': normalized, 'otp': otp, 'name': name, 'email': email, 'role': role, 'mode': 'register'}),
    );
    if (!_ok(res.statusCode)) throw Exception(res.body.isNotEmpty ? res.body : 'Registration failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _persistSession(
      accessToken: data['access_token'] as String? ?? '',
      userId:      data['user_id']      as String? ?? '',
      role:        data['role']         as String? ?? 'CUSTOMER',
      phone:       normalized,
    );
    if (data['worker_id'] != null && data['worker_id'].toString().isNotEmpty) {
      await persistWorkerId(data['worker_id'].toString());
    }
    return data;
  }
}
