import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "auth/login.dart";
import "screens/home_screen.dart";
import "core/services/mock_database.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Wink Wash",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2B4A)),
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: MockDatabase.instance.auth.isLoggedIn,
        builder: (context, isLoggedIn, child) {
          if (isLoggedIn) {
            return const HomeScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
