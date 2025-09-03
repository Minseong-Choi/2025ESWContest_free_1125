import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final api = ApiService();
  List<String> _questions = [];
  bool _isLoading = false;

  // 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _questions = [];
        _isLoading = true; // 질문 생성 중
      });

      await _uploadImage();
    }
  }

  // 서버에 업로드 + 질문 받기
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final response = await api.uploadImage(_selectedImage!);
    if (response != null) {
      List<String> questions = List<String>.from(response['questions'] ?? []);

      // 질문을 순차적으로 화면에 추가
      for (int i = 0; i < questions.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _questions.add(questions[i]);
        });
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("질문 생성 완료!")),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("업로드 실패")),
      );
    }
  }

  // 갤러리/카메라 선택 다이얼로그
  void _showPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("갤러리에서 선택"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("카메라로 촬영"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text(
          "사진으로 추억 되살리기",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade300,
        toolbarHeight: 70,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPickOptions(context),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(4, 6),
                    ),
                  ],
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo,
                        size: 50, color: Colors.black38),
                    SizedBox(height: 10),
                    Text(
                      "(클릭하여 사진 업로드)",
                      style:
                      TextStyle(fontSize: 16, color: Colors.black38),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 📌 사진 업로드 안내 문구 (업로드 전만)
            if (_selectedImage == null)
              const Text(
                "추억을 회상하고 싶은 사진을 업로드해보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, color: Colors.black54),
              ),

            // 📌 로딩 문구
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  "질문을 생성중이에요...",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 20),

            // 질문 리스트
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _questions[index],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                          // 🎙 녹음 버튼 자리만 표시
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}