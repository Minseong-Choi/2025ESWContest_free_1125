// lib/models/drawing_model.dart
enum DrawingStage {
  oneThird,
  twoThirds,
  complete,
}

// lib/models/drawing_model.dart
class DrawingData {
  final String name;
  final String imageUrl;
  final List<String> wrongAnswers;
  final String category; // 추가

  DrawingData({
    required this.name,
    required this.imageUrl,
    required this.wrongAnswers,
    required this.category, // 생성자에 추가
  });

  // JSON -> 객체
  factory DrawingData.fromJson(Map<String, dynamic> json, {required String category}) {
    return DrawingData(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      wrongAnswers: List<String>.from(json['wrongAnswers'] ?? []),
      category: category, // API 호출 시 넣어주는 카테고리
    );
  }

  // 객체 -> JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'wrongAnswers': wrongAnswers,
      'category': category,
    };
  }
}