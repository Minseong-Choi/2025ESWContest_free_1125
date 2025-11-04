// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../models/drawing_model.dart';

class ApiService {
  // 로컬 서버 IP와 포트
  final String baseUrl = "http://192.168.0.14:5001"; // PC IP 에 맞춰서 변경

  Future<DrawingData> getRandomDrawing(String category) async {
    final url = Uri.parse('$baseUrl/api/random/$category');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final imageUrl = data['imageUrl'].toString().startsWith('http')
            ? data['imageUrl']
            : '$baseUrl${data['imageUrl']}';

        return DrawingData(
          name: data['name'],
          category: category,
          imageUrl: imageUrl,
          part1JsonUrl: data['part1JsonUrl'] != null
              ? (data['part1JsonUrl'].toString().startsWith('http')
                  ? data['part1JsonUrl']
                  : '$baseUrl${data['part1JsonUrl']}')
              : null,
          part2JsonUrl: data['part2JsonUrl'] != null
              ? (data['part2JsonUrl'].toString().startsWith('http')
                  ? data['part2JsonUrl']
                  : '$baseUrl${data['part2JsonUrl']}')
              : null,
          part3JsonUrl: data['part3JsonUrl'] != null
              ? (data['part3JsonUrl'].toString().startsWith('http')
                  ? data['part3JsonUrl']
                  : '$baseUrl${data['part3JsonUrl']}')
              : null,
          part1Contours: data['part1Contours'] != null
              ? List<List<List<num>>>.from(
                  (data['part1Contours'] as List).map((e) => 
                    List<List<num>>.from((e as List).map((f) => 
                      List<num>.from((f as List).map((g) => (g as num)))
                    ))
                  ))
                )
              : null,
          part2Contours: data['part2Contours'] != null
              ? List<List<List<num>>>.from(
                  (data['part2Contours'] as List).map((e) => 
                    List<List<num>>.from((e as List).map((f) => 
                      List<num>.from((f as List).map((g) => (g as num)))
                    ))
                  ))
                )
              : null,
          part3Contours: data['part3Contours'] != null
              ? List<List<List<num>>>.from(
                  (data['part3Contours'] as List).map((e) => 
                    List<List<num>>.from((e as List).map((f) => 
                      List<num>.from((f as List).map((g) => (g as num)))
                    ))
                  ))
                )
              : null,
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

  Future<bool> drawOnEv3(String? jsonUrl, {List<List<List<num>>>? contours}) async {
    if (jsonUrl != null) {
      final url = Uri.parse('$baseUrl/api/draw');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'jsonUrl': jsonUrl}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('EV3 draw success: ${data['file']}');
          return true;
        } else {
          final data = json.decode(response.body);
          print('EV3 draw failed: ${data['error']}');
          return false;
        }
      } catch (e) {
        print('Error sending draw request to EV3: $e');
        return false;
      }
    } else if (contours != null) {
      final url = Uri.parse('$baseUrl/api/draw/contours');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'contours': contours}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('EV3 draw success with contours');
          return true;
        } else {
          final data = json.decode(response.body);
          print('EV3 draw failed: ${data['error']}');
          return false;
        }
      } catch (e) {
        print('Error sending draw request to EV3: $e');
        return false;
      }
    }
    return false;
  }
  // ✅ 이미지 업로드 (갤러리/카메라)
  Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    final uri = Uri.parse("$baseUrl/api/upload");
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: basename(imageFile.path),
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = json.decode(resStr);
        return data; // questions만 포함
      } else {
        print("이미지 업로드 실패: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // 요청 텍스트 전송
  Future<Map<String, dynamic>?> sendRequest(String text) async {
    final url = Uri.parse('$baseUrl/api/request'); // Flask endpoint

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("요청 성공: $data");
        return data; // ✅ imageUrl, message 같이 반환
      } else {
        print("요청 실패: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("에러 발생: $e");
      return null;
    }
  }
}



