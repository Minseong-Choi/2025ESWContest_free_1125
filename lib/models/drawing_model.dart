// lib/models/drawing_model.dart
enum DrawingStage {
  oneThird,
  twoThirds,
  complete,
}

class DrawingData {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> wrongAnswers;

  DrawingData({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.wrongAnswers,
  });

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      wrongAnswers: List<String>.from(json['wrongAnswers']),
    );
  }
}