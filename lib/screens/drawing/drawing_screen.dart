// lib/screens/drawing/drawing_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/api_service.dart';
import '../../services/bluetooth_service.dart';
import '../../models/drawing_model.dart';

class DrawingScreen extends StatefulWidget {
  final String category;

  const DrawingScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final ApiService _apiService = ApiService();
  final BluetoothService _bluetoothService = BluetoothService();

  DrawingStage _currentStage = DrawingStage.oneThird;
  DrawingData? _drawingData;
  String? _selectedAnswer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrawing();
  }

  Future<void> _loadDrawing() async {
    setState(() => _isLoading = true);

    try {
      final drawingData = await _apiService.getRandomDrawing(widget.category);

      setState(() {
        _drawingData = drawingData;
        _isLoading = false;
      });

      // EV3에 1/3 그리기 명령 전송
      await _bluetoothService.sendDrawCommand(
        imageUrl: _drawingData!.imageUrl,
        stage: DrawingStage.oneThird,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog();
    }
  }

  List<String> get _options {
    if (_drawingData == null) return [];
    final options = [_drawingData!.name, ..._drawingData!.wrongAnswers];
    options.shuffle(Random());
    return options.take(3).toList();
  }

  void _checkAnswer(String answer) {
    setState(() => _selectedAnswer = answer);

    if (answer == _drawingData!.name) {
      _showCorrectDialog();
    } else {
      _moveToTwoThirds();
    }
  }

  void _moveToTwoThirds() async {
    setState(() {
      _currentStage = DrawingStage.twoThirds;
      _selectedAnswer = null;
    });

    await _bluetoothService.sendDrawCommand(
      imageUrl: _drawingData!.imageUrl,
      stage: DrawingStage.twoThirds,
    );
  }

  void _completeDrawing() async {
    setState(() => _currentStage = DrawingStage.complete);

    await _bluetoothService.sendDrawCommand(
      imageUrl: _drawingData!.imageUrl,
      stage: DrawingStage.complete,
    );

    _showRetryDialog();
  }

  void _showCorrectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 40),
            const SizedBox(width: 10),
            const Text(
              '정답입니다!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '무엇을 하시겠습니까?',
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDrawingCompleteScreen();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: const Text(
              '내가 그리기',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeDrawing();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: const Text(
              '남은 테두리 완성하기',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '그림 완성! 정답은 "${_drawingData!.name}"',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '다시 도전하시겠습니까?',
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: const Text(
              '카테고리 선택',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAndLoadNew();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDrawingCompleteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingCompleteScreen(
          onNext: _resetAndLoadNew,
          onHome: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _resetAndLoadNew() {
    setState(() {
      _currentStage = DrawingStage.oneThird;
      _selectedAnswer = null;
      _drawingData = null;
    });
    _loadDrawing();
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류', style: TextStyle(fontSize: 24)),
        content: const Text(
          '그림을 불러오는데 실패했습니다.\n다시 시도해주세요.',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('돌아가기', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} 그리기',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade300,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(size: 30),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 진행 상태 표시
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.brush,
                      color: Colors.purple.shade400,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _currentStage == DrawingStage.oneThird
                          ? '1/3 그리기 중...'
                          : _currentStage == DrawingStage.twoThirds
                          ? '2/3 그리기 중...'
                          : '완성!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 그림 영역 (실제로는 EV3가 그리고 있음)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.shade200,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 80,
                        color: Colors.purple.shade300,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'EV3 로봇이 그림을 그리고 있어요!',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 선택지 버튼들
              if (_currentStage != DrawingStage.complete)
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        '무엇을 그리고 있을까요?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...(_options.map((option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedAnswer == null
                                ? () => _checkAnswer(option)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedAnswer == option
                                  ? (option == _drawingData!.name
                                  ? Colors.green.shade400
                                  : Colors.red.shade400)
                                  : Colors.amber.shade300,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )).toList()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 그리기 완료 화면
class DrawingCompleteScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onHome;

  const DrawingCompleteScreen({
    Key? key,
    required this.onNext,
    required this.onHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade100,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration,
                size: 100,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 30),
              const Text(
                '이제 직접 그려보세요!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '종이에 멋진 그림을 완성해보세요',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '홈으로',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '다음 그림',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}