import 'package:find_your_way/provider/map_data.dart';
import 'package:find_your_way/provider/trilateration_data.dart';
import 'package:find_your_way/provider/user_data.dart';
import 'package:find_your_way/widgets/home/home.dart';
import 'package:find_your_way/widgets/login/login.dart';
import 'package:find_your_way/widgets/login/splash_screen.dart';
import 'package:find_your_way/widgets/signup/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserData>(
          create: (context) => UserData(),
        ),
        ChangeNotifierProvider<MapData>(
          create: (context) => MapData(),
        ),
        ChangeNotifierProvider<TrilaterationData>(
          create: (context) => TrilaterationData(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Your Way',
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
        '/signup': (context) => const Signup(),
        '/home': (context) => const Home(),
      },
    );
  }
}
