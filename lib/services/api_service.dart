// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../models/drawing_model.dart';

class ApiService {
  // 로컬 서버 IP와 포트
  final String baseUrl = "http://192.168.0.14:5001"; // PC IP 에 맞춰서 변경

  // 랜덤 이미지 가져오기
  Future<DrawingData> getRandomDrawing(String category) async {
    final url = Uri.parse('$baseUrl/api/random/$category');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return DrawingData(
          name: data['name'],
          category: category,
          imageUrl: '$baseUrl${data['imageUrl']}',
          part1JsonUrl: '$baseUrl${data['part1JsonUrl']}',
          part2JsonUrl: '$baseUrl${data['part2JsonUrl']}',
          part3JsonUrl: '$baseUrl${data['part3JsonUrl']}',
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

  // 선택한 이미지로 EV3에 그림 그리기 요청
  // EV3에 특정 JSON 경로를 전송해서 그림 그리기
  Future<bool> drawOnEv3(String jsonUrl) async {
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
  }
  // ✅ 이미지 업로드 (갤러리/카메라)
  // 업로드 함수 반환값을 Map으로 바꾸기
  Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    final uri = Uri.parse("$baseUrl/api/upload"); // /api/upload로 변경
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
        return data; // questions + audioFiles 포함
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



