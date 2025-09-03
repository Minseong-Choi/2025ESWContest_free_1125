import 'package:flutter/material.dart';
import '../category/category_screen.dart';
import '../gallery/gallery_screen.dart';
import '../request/request_screen.dart';

class ContentsScreen extends StatelessWidget {
  const ContentsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> contents = const [
    {'name': '그림 퀴즈', 'icon': Icons.draw, 'color': Color(0xFFFFB3BA)},
    {'name': '사진 업로드', 'icon': Icons.picture_in_picture, 'color': Color(0xFFBAE1FF)},
    {'name': '그림 요청하기', 'icon': Icons.color_lens, 'color': Color(0xFFFFDFBA)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text(
          "무엇을 해볼까요?",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade300,
        toolbarHeight: 80,
        centerTitle: true,
        iconTheme: const IconThemeData(size: 30, color: Colors.white),
      ),
      body: Center( // ✅ 화면 정중앙 배치
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙
          children: [
            _buildPlayfulButton(contents[0], context, size: 200),
            const SizedBox(height: 30),
            _buildPlayfulButton(contents[1], context, size: 200),
            const SizedBox(height: 30),
            _buildPlayfulButton(contents[2], context, size: 200), // 밑에 조금 더 큼
          ],
        ),
      ),
    );
  }

  Widget _buildPlayfulButton(Map<String, dynamic> item, BuildContext context,
      {double size = 180}) {
    return InkWell(
      onTap: () {
        Widget nextScreen;

        if (item['name'] == '그림 퀴즈') {
          nextScreen = const CategoryScreen();
        } else if (item['name'] == '사진 업로드') {
          nextScreen = const GalleryScreen();
        } else {
          nextScreen = const RequestScreen();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: item['color'],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: item['color'].withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: size * 0.35, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              item['name'],
              style: TextStyle(
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}