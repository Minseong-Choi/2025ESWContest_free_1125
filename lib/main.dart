// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const DementiaPreventionApp());
}

class DementiaPreventionApp extends StatelessWidget {
  const DementiaPreventionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '즐거운 그림 그리기',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 기본 시스템 폰트 사용
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 24),
          bodyMedium: TextStyle(fontSize: 20),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}