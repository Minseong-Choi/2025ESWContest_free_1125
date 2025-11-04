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
  final String? part1JsonUrl;
  final String? part2JsonUrl;
  final String? part3JsonUrl;
  final List<List<List<num>>>? part1Contours;
  final List<List<List<num>>>? part2Contours;
  final List<List<List<num>>>? part3Contours;
  final List<String> wrongAnswers;
  final String category;

  DrawingData({
    required this.name,
    required this.imageUrl,
    this.part1JsonUrl,
    this.part2JsonUrl,
    this.part3JsonUrl,
    this.part1Contours,
    this.part2Contours,
    this.part3Contours,
    required this.wrongAnswers,
    required this.category,
  });

  factory DrawingData.fromJson(Map<String, dynamic> json, {required String category}) {
    return DrawingData(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      part1JsonUrl: json['part1JsonUrl'] as String?,
      part2JsonUrl: json['part2JsonUrl'] as String?,
      part3JsonUrl: json['part3JsonUrl'] as String?,
      part1Contours: json['part1Contours'] != null
          ? List<List<List<num>>>.from(
              (json['part1Contours'] as List).map((e) => 
                List<List<num>>.from((e as List).map((f) => 
                  List<num>.from((f as List).map((g) => (g as num)))
                ))
              ))
            )
          : null,
      part2Contours: json['part2Contours'] != null
          ? List<List<List<num>>>.from(
              (json['part2Contours'] as List).map((e) => 
                List<List<num>>.from((e as List).map((f) => 
                  List<num>.from((f as List).map((g) => (g as num)))
                ))
              ))
            )
          : null,
      part3Contours: json['part3Contours'] != null
          ? List<List<List<num>>>.from(
              (json['part3Contours'] as List).map((e) => 
                List<List<num>>.from((e as List).map((f) => 
                  List<num>.from((f as List).map((g) => (g as num)))
                ))
              ))
            )
          : null,
      wrongAnswers: List<String>.from(json['wrongAnswers'] ?? []),
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'part1JsonUrl': part1JsonUrl,
      'part2JsonUrl': part2JsonUrl,
      'part3JsonUrl': part3JsonUrl,
      'part1Contours': part1Contours,
      'part2Contours': part2Contours,
      'part3Contours': part3Contours,
      'wrongAnswers': wrongAnswers,
      'category': category,
    };
  }
}