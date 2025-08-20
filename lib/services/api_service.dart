// lib/services/api_service.dart
import 'dart:math';
import '../models/drawing_model.dart';

class ApiService {
  final Random _random = Random();

  Future<DrawingData> getRandomDrawing(String category) async {
    // 2초 지연으로 네트워크 통신 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));

    // 더미 데이터 반환
    return _getDummyData(category);
  }

  // 테스트용 더미 데이터 - 카테고리별로 여러 개 준비
  DrawingData _getDummyData(String category) {
    final Map<String, List<DrawingData>> allData = {
      '동물': [
        DrawingData(
          id: '1',
          name: '고양이',
          category: '동물',
          imageUrl: 'dummy_cat.jpg',
          wrongAnswers: ['강아지', '토끼', '햄스터', '새', '거북이', '물고기'],
        ),
        DrawingData(
          id: '2',
          name: '강아지',
          category: '동물',
          imageUrl: 'dummy_dog.jpg',
          wrongAnswers: ['고양이', '토끼', '햄스터', '새', '거북이', '물고기'],
        ),
        DrawingData(
          id: '3',
          name: '토끼',
          category: '동물',
          imageUrl: 'dummy_rabbit.jpg',
          wrongAnswers: ['고양이', '강아지', '햄스터', '새', '거북이', '물고기'],
        ),
      ],
      '과일': [
        DrawingData(
          id: '4',
          name: '사과',
          category: '과일',
          imageUrl: 'dummy_apple.jpg',
          wrongAnswers: ['배', '포도', '오렌지', '바나나', '딸기', '수박'],
        ),
        DrawingData(
          id: '5',
          name: '바나나',
          category: '과일',
          imageUrl: 'dummy_banana.jpg',
          wrongAnswers: ['사과', '배', '포도', '오렌지', '딸기', '수박'],
        ),
      ],
      '사물': [
        DrawingData(
          id: '6',
          name: '우산',
          category: '사물',
          imageUrl: 'dummy_umbrella.jpg',
          wrongAnswers: ['가방', '모자', '신발', '시계', '안경', '컵'],
        ),
        DrawingData(
          id: '7',
          name: '시계',
          category: '사물',
          imageUrl: 'dummy_watch.jpg',
          wrongAnswers: ['우산', '가방', '모자', '신발', '안경', '컵'],
        ),
      ],
      '꽃': [
        DrawingData(
          id: '8',
          name: '장미',
          category: '꽃',
          imageUrl: 'dummy_rose.jpg',
          wrongAnswers: ['해바라기', '튤립', '백합', '국화', '코스모스', '진달래'],
        ),
        DrawingData(
          id: '9',
          name: '해바라기',
          category: '꽃',
          imageUrl: 'dummy_sunflower.jpg',
          wrongAnswers: ['장미', '튤립', '백합', '국화', '코스모스', '진달래'],
        ),
      ],
      '화투': [
        DrawingData(
          id: '10',
          name: '솔',
          category: '화투',
          imageUrl: 'dummy_pine.jpg',
          wrongAnswers: ['매화', '벚꽃', '국화', '단풍', '모란', '난초'],
        ),
        DrawingData(
          id: '11',
          name: '벚꽃',
          category: '화투',
          imageUrl: 'dummy_cherry.jpg',
          wrongAnswers: ['솔', '매화', '국화', '단풍', '모란', '난초'],
        ),
      ],
      '탈것': [
        DrawingData(
          id: '12',
          name: '자동차',
          category: '탈것',
          imageUrl: 'dummy_car.jpg',
          wrongAnswers: ['자전거', '버스', '기차', '비행기', '배', '오토바이'],
        ),
        DrawingData(
          id: '13',
          name: '자전거',
          category: '탈것',
          imageUrl: 'dummy_bicycle.jpg',
          wrongAnswers: ['자동차', '버스', '기차', '비행기', '배', '오토바이'],
        ),
      ],
    };

    final categoryData = allData[category] ?? allData['동물']!;
    return categoryData[_random.nextInt(categoryData.length)];
  }
}