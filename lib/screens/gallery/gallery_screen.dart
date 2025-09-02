// lib/screens/gallery/gallery_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:audioplayers/audioplayers.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final api = ApiService(); // ApiService 인스턴스
  List<String> _questions = [];
  List<String> _audioUrls = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _questions = [];
        _audioUrls = [];
      });

      // 선택 후 바로 업로드 실행
      await _uploadImage();
    }
  }

  // 이미지 업로드 + 질문/음성 받기
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final response = await api.uploadImage(_selectedImage!);
    if (response != null) {
      setState(() {
        _questions = List<String>.from(response['questions'] ?? []);
        _audioUrls = List<String>.from(response['audioFiles'] ?? []);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미지 업로드 성공! 질문과 음성이 생성되었습니다.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("업로드 실패")),
      );
    }
  }

  void _playAudio(String url) async {
    await _audioPlayer.stop(); // 기존 재생 중이면 중지
    await _audioPlayer.play(UrlSource(url));
  }

  void _showPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("갤러리에서 선택"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("카메라 촬영"),
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
      appBar: AppBar(
        title: const Text(
          "사진 업로드",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade300,
        toolbarHeight: 70,
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
                ),
                child: _selectedImage == null
                    ? const Center(
                  child: Text(
                    "사진 업로드",
                    style: TextStyle(fontSize: 20, color: Colors.black54),
                  ),
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
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(_questions[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          if (index < _audioUrls.length) {
                            _playAudio(_audioUrls[index]);
                          }
                        },
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