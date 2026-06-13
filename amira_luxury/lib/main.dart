import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AmiraApp());
}

class AmiraApp extends StatelessWidget {
  const AmiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amira Luxury',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Satoshi',
        scaffoldBackgroundColor: const Color(0xFFF2F2EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C2C2C),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
