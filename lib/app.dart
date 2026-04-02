import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "auth/login.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("App: Rendering old UI style (MaterialApp)...");

    return MaterialApp(
      title: "Wink Wash",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2B4A)),
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
      ),
      // We use direct home for reliability as per user request for "old ui"
      home: const LoginPage(),
    );
  }
}
