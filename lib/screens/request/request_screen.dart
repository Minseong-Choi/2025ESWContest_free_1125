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

  String? _imageUrl;  // 서버에서 받은 이미지 URL
  String? _message;   // 서버에서 받은 메시지
  bool _loading = false; // 요청 진행 상태

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
            const Text(
              "무엇을 그려드릴까요?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "예: 귀여운 강아지, 우주 배경의 풍경 등",
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
            ElevatedButton(
              onPressed: _loading ? null : _submitRequest,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "요청 보내기",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
                child: Image.network(
                  _imageUrl!,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}