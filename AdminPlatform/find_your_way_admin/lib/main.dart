import 'package:find_your_way_admin/home/home.dart';
import 'package:find_your_way_admin/login/login.dart';
import 'package:find_your_way_admin/login/splash_screen.dart';
import 'package:find_your_way_admin/provider/user_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider<UserData>(
        create: (context) => UserData(),
      ),
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Your Way Admin',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF118ab2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF118ab2),
          secondary: Color(0xFFef476f),
          tertiary: Color(0xFF06d6a0),
          shadow: Color(0xFF073b4c),
        ),
        highlightColor: const Color(0xFFffd166),
        fontFamily: GoogleFonts.fredokaOne().fontFamily,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const Login(),
        '/home': (context) => const Home(),
      },
    );
  }
}
