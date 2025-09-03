// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../contents/contents_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade100,
              Colors.pink.shade100,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.palette,
                size: 150,
                color: Colors.deepOrange.shade300,
              ),
              const SizedBox(height: 40),
              Text(
                'Draw-care',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '해마  기능 자극 기반 치매 예방 프로그램',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContentsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}