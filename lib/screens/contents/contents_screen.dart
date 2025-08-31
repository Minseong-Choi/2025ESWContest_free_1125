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
      appBar: AppBar(
        title: const Text(
          '카테고리 선택',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade300,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(size: 30),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.yellow.shade50,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
            ),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final item = contents[index];

              return CategoryButton(
                name: item['name'],
                icon: item['icon'],
                color: item['color'],
                onTap: () {
                  Widget nextScreen;

                  if (item['name'] == '그림 퀴즈') {
                    nextScreen = CategoryScreen();
                  } else if (item['name'] == '사진 업로드') {
                    nextScreen = GalleryScreen();
                  } else if (item['name'] == '그림 요청하기') {
                    nextScreen = RequestScreen();
                  } else {
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => nextScreen),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CategoryButton({
    Key? key,
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              name,
              style: const TextStyle(
                fontSize: 26,
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