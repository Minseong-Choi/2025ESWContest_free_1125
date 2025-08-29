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
  final String part1JsonUrl;
  final String part2JsonUrl;
  final String part3JsonUrl;
  final List<String> wrongAnswers;
  final String category; // 추가

  DrawingData({
    required this.name,
    required this.imageUrl,
    required this.part1JsonUrl,
    required this.part2JsonUrl,
    required this.part3JsonUrl,
    required this.wrongAnswers,
    required this.category, // 생성자에 추가
  });

  // JSON -> 객체
  factory DrawingData.fromJson(Map<String, dynamic> json, {required String category}) {
    return DrawingData(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      part1JsonUrl: json['part1JsonUrl'] as String,
      part2JsonUrl: json['part2JsonUrl'] as String,
      part3JsonUrl: json['part3JsonUrl'] as String,
      wrongAnswers: List<String>.from(json['wrongAnswers'] ?? []),
      category: category,
    );
  }

  // 객체 -> JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'part1JsonUrl': part1JsonUrl,
      'part2JsonUrl': part2JsonUrl,
      'part3JsonUrl': part3JsonUrl,
      'wrongAnswers': wrongAnswers,
      'category': category,
    };
  }
}