
// lib/services/bluetooth_service.dart
import 'dart:convert';
import '../models/drawing_model.dart';

class BluetoothService {
  bool _isSimulationMode = true; // 시뮬레이션 모드 활성화

  // EV3 장치 검색 및 연결 (시뮬레이션)
  Future<bool> connectToEV3() async {
    print("시뮬레이션 모드: EV3 연결 시뮬레이션");
    await Future.delayed(const Duration(seconds: 1));
    return true; // 항상 연결 성공으로 가정
  }

  // EV3에 그리기 명령 전송 (시뮬레이션)
  Future<void> sendDrawCommand({
    required String imageUrl,
    required DrawingStage stage,
  }) async {
    // 명령 데이터 생성
    Map<String, dynamic> command = {
      'action': 'draw',
      'imageUrl': imageUrl,
      'stage': stage.toString().split('.').last,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    String jsonCommand = json.encode(command);
    print("시뮬레이션: EV3에 명령 전송 - $jsonCommand");

    // 각 단계별로 다른 지연 시간 시뮬레이션
    switch (stage) {
      case DrawingStage.oneThird:
        await Future.delayed(const Duration(seconds: 2));
        print("시뮬레이션: 1/3 그리기 완료");
        break;
      case DrawingStage.twoThirds:
        await Future.delayed(const Duration(seconds: 2));
        print("시뮬레이션: 2/3 그리기 완료");
        break;
      case DrawingStage.complete:
        await Future.delayed(const Duration(seconds: 2));
        print("시뮬레이션: 그림 완성!");
        break;
    }
  }

  // 연결 해제 (시뮬레이션)
  Future<void> disconnect() async {
    print("시뮬레이션: EV3 연결 해제");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // 연결 상태 확인 (시뮬레이션에서는 항상 true)
  bool get isConnected => _isSimulationMode;
}