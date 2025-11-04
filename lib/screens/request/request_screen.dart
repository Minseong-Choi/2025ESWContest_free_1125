import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({Key? key}) : super(key: key);

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final TextEditingController _textController = TextEditingController();
  final api = ApiService(); // ApiService 인스턴스

  String? _imageUrl;
  String? _message;
  List<List<List<num>>>? _part1Contours;
  List<List<List<num>>>? _part2Contours;
  List<List<List<num>>>? _part3Contours;
  bool _loading = false;

  void _submitRequest() async {
    final requestText = _textController.text.trim();
    if (requestText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("내용을 입력해주세요!")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _imageUrl = null;
      _message = null;
    });

    final result = await api.sendRequest(requestText);

    setState(() {
      _loading = false;
    });

    if (result != null) {
      setState(() {
        _imageUrl = result["imageUrl"];
        _message = result["message"] ?? "그림이 완성되었습니다!";
        if (result["part1Contours"] != null) {
          _part1Contours = List<List<List<num>>>.from(
            (result["part1Contours"] as List).map((e) => 
              List<List<num>>.from((e as List).map((f) => 
                List<num>.from((f as List).map((g) => (g as num)))
              ))
            )
          );
        }
        if (result["part2Contours"] != null) {
          _part2Contours = List<List<List<num>>>.from(
            (result["part2Contours"] as List).map((e) => 
              List<List<num>>.from((e as List).map((f) => 
                List<num>.from((f as List).map((g) => (g as num)))
              ))
            )
          );
        }
        if (result["part3Contours"] != null) {
          _part3Contours = List<List<List<num>>>.from(
            (result["part3Contours"] as List).map((e) => 
              List<List<num>>.from((e as List).map((f) => 
                List<num>.from((f as List).map((g) => (g as num)))
              ))
            )
          );
        }
      });
      _textController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("요청 전송 실패")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "그림 요청하기",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade300,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 중앙 정렬된 타이틀
            const Center(
              child: Text(
                "무엇을 그려드릴까요?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // 입력창
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "예: 무지개 위를 달리는 고양이, 구름 위에 앉은 토끼 등",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // 버튼
            ElevatedButton(
              onPressed: _loading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade300,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "요청 보내기",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // 흰색으로 지정
              ),
            ),

            const SizedBox(height: 30),

            if (_message != null) ...[
              Text(
                _message!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_imageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}