import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/mock_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mock Database (no real backend)
  MockDatabase.instance; 

  runApp(const App());
}
