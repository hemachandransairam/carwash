import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthApiService _api = AuthApiService();

  String? get currentUserPhone => _api.currentUserPhone;
  String? get userId => _api.userId;

  Future<void> initUser() async {
    await _api.loadSession();
  }

  Future<bool> checkPhone(String phone) async {
    return _api.checkPhone(phone);
  }

  Future<void> sendOtp(String phone) async {
    await _api.sendOtp(phone);
  }

  Future<Map<String, dynamic>> login(String phone, String otp) async {
    final result = await _api.login(phone, otp);
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String otp,
    String role = 'CUSTOMER',
  }) async {
    final result = await _api.register(name: name, email: email, phone: phone, otp: otp, role: role);
    return result;
  }
}
