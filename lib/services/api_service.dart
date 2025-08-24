// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drawing_model.dart';

class ApiService {
  // 로컬 서버 IP와 포트
  final String baseUrl = "http://192.168.0.4:5001";

  Future<DrawingData> getRandomDrawing(String category) async {
    final url = Uri.parse('$baseUrl/api/random/$category');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 서버 형식에 맞춰 DrawingData 생성
        return DrawingData(
          name: data['name'],
          category: category,
          imageUrl: '$baseUrl${data['imageUrl']}',
          wrongAnswers: List<String>.from(data['wrongAnswers']),
        );
      } else {
        throw Exception('Failed to load drawing data');
      }
    } catch (e) {
      print('Error fetching drawing data: $e');
      rethrow;
    }
  }
}