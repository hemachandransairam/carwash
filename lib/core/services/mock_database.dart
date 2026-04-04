import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../config/supabase_config.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._();
  MockDatabase._();

  final MockAuth auth = MockAuth();
  SupabaseClient get client => Supabase.instance.client;

  SupabaseQueryBuilder from(String table) {
    // Exact mapping for your latest schema
    final Map<String, String> tableMap = {
      'profiles': 'users',
      'user_addresses': 'addresses',
      'personal_details': 'users',
      'user_vehicles': 'vehicles',
      'vehicle_services': 'booking_vehicle_services',
      'user_payments': 'payments',
    };
    
    final targetTable = tableMap[table] ?? table;
    return client.from(targetTable);
  }

  Stream<List<Map<String, dynamic>>> getStream(String table, {required List<String> primaryKey}) {
    final Map<String, String> tableMap = {
      'profiles': 'users',
      'user_addresses': 'addresses',
      'user_vehicles': 'vehicles',
    };
    final targetTable = tableMap[table] ?? table;
    return client.from(targetTable).stream(primaryKey: primaryKey);
  }
}

class MockAuth {
  Map<String, dynamic>? _sessionUser;
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('saved_user_session');
    if (userJson != null) {
      _sessionUser = jsonDecode(userJson);
      isLoggedIn.value = true;
    }
  }

  void _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionUser != null) {
      await prefs.setString('saved_user_session', jsonEncode(_sessionUser));
      isLoggedIn.value = true;
    } else {
      await prefs.remove('saved_user_session');
      isLoggedIn.value = false;
    }
  }

  void updateSessionUser(Map<String, dynamic> user) {
    _sessionUser = user;
    _saveSession();
  }

  Map<String, dynamic>? get currentUser {
    if (_sessionUser != null) return _sessionUser;
    
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;
    
    return {
      'id': authUser.id, 
      'phone': authUser.phone,
      'email': authUser.email,
      'user_metadata': authUser.userMetadata,
    };
  }

  String _normalizePhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length == 10 ? '91$d' : d;
  }

  Future<bool> checkPhone(String phone) async {
    final String cleanPhone = _normalizePhone(phone);
    final res = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/check-phone'),
      headers: {
        'Content-Type': 'application/json', 
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      },
      body: jsonEncode({'phone': cleanPhone}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return false;
    final data = jsonDecode(res.body);
    return data['exists'] == true;
  }

  /// DIRECT META WhatsApp API FLOW (To Debug the Error)
  Future<void> signInWithOtp({required String phone}) async {
    final String cleanPhone = _normalizePhone(phone);
    final String generatedOtp = (100000 + (999999 - 100000) * (DateTime.now().millisecond / 1000)).floor().toString();

    // 1. Save to Supabase otp_store directly
    final String token = "EAANF8ZCkAkSMBQ7fXCC1HM6oW0XIuChDlECEAXZB4az6JqpdiEXZBGCrbdK1lgHJtUw8qTZBeF1HeudHlF0qKZBPnTXBpsQWARZBcOowVccujNWT7kgpSkQkONpeMGZAAWjPLeSu6DOhFQomcTAaKQWg34qaSf5PJMONg27wqewcZC9tSczIMPg8DvykReGg9kkTZA67mLZBC4lDRnMA738KHIpUZAgCuiFZACZCBSp4xKZAda";
    final String phoneId = "1069501402909893";

    await Supabase.instance.client.from('otp_store').upsert({
      'phone': cleanPhone,
      'otp': generatedOtp,
      'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
    }).build();

    print("--- DIRECT SENDING TO WHATSAPP to $cleanPhone ---");
    print("TOKEN START: ${token.substring(0, 10)}...");
    
    final response = await http.post(
      Uri.parse("https://graph.facebook.com/v17.0/$phoneId/messages"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "messaging_product": "whatsapp",
        "to": cleanPhone, 
        "type": "template",
        "template": {
          "name": "otp_verification",
          "language": {"code": "en_GB"},
          "components": [
            {
              "type": "body",
              "parameters": [
                {"type": "text", "text": generatedOtp}
              ]
            }
          ]
        }
      }),
    );
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Provide exact JSON error from Meta
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] ?? response.body;
      throw Exception("Meta Error: $msg");
    }
  }

  /// Custom OTP Verification + Backend Lookup Logic
  Future<void> verifyOtp({required String phone, required String token, required dynamic type}) async {
    final String cleanPhone = _normalizePhone(phone);

    // 1. Check if user already exists
    final checkRes = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/check-phone'),
      headers: {
        'Content-Type': 'application/json', 
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      },
      body: jsonEncode({'phone': cleanPhone}),
    );
    
    if (checkRes.statusCode < 200 || checkRes.statusCode >= 300) {
      throw Exception("User lookup failed: ${checkRes.body}");
    }
    
    final bool exists = jsonDecode(checkRes.body)['exists'] == true;

    // 2. Verify OTP with Backend Edge Function
    if (exists) {
      // Old user: Login
      final loginRes = await http.post(
        Uri.parse('${SupabaseConfig.url}/functions/v1/verify-otp'),
        headers: {
          'Content-Type': 'application/json', 
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: jsonEncode({'phone': cleanPhone, 'otp': token, 'mode': 'login'}),
      );
      
      if (loginRes.statusCode < 200 || loginRes.statusCode >= 300) {
        throw Exception(loginRes.body.isNotEmpty ? loginRes.body : "Invalid OTP");
      }
      
      final data = jsonDecode(loginRes.body);
      
      // Ensure only USERs can log into this app
      final String userRole = data['role']?.toString().toUpperCase() ?? 'USER';
      if (userRole != 'USER') {
        throw Exception("This account is not a customer account. Please use the relevant app.");
      }
      
      // Try to fetch full profile from DB
      final profile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('phone', cleanPhone)
          .maybeSingle();

      if (profile != null) {
        _sessionUser = {...profile, 'role': userRole};
      } else {
        _sessionUser = {
          'id': data['user_id'], 
          'phone': cleanPhone, 
          'is_new': false, 
          'role': userRole
        };
      }
    } else {
      // New User: Register stub account to verify OTP
      final regRes = await http.post(
        Uri.parse('${SupabaseConfig.url}/functions/v1/verify-otp'),
        headers: {
          'Content-Type': 'application/json', 
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: jsonEncode({
          'phone': cleanPhone, 
          'otp': token, 
          'mode': 'register',
          'name': '',
          'email': '',
          'role': 'USER'
        }),
      );
      
      if (regRes.statusCode < 200 || regRes.statusCode >= 300) {
        throw Exception(regRes.body.isNotEmpty ? regRes.body : "Invalid OTP");
      }
      
      final data = jsonDecode(regRes.body);
      _sessionUser = {
        'id': data['user_id'], 
        'phone': cleanPhone, 
        'is_new': true, 
        'role': data['role'] ?? 'USER'
      };
    }
    
    _saveSession();
  }


  Future<void> signOut() async {
    _sessionUser = null;
    _saveSession();
    await Supabase.instance.client.auth.signOut();
  }
}

extension PostgrestBuilderExtension on PostgrestFilterBuilder {
  Future<T> build<T>() async {
    final response = await this;
    return response as T;
  }
}

extension PostgrestTransformBuilderExtension on PostgrestTransformBuilder {
  Future<T> build<T>() async {
    final response = await this;
    return response as T;
  }
}
