import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before running the app
  try {
    await Supabase.initialize(
      url: "https://qxxsclrmpscofinjedjz.supabase.co",
      anonKey: "sb_publishable_bWTgLtV7gE2xJ5qZsM--FA_QPxL20_Y",
    );
  } catch (e) {
    debugPrint("Supabase initialization note: $e");
  }

  runApp(const App());
}
