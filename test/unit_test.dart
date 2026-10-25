import 'package:flutter_test/flutter_test.dart';
import 'package:cube_iii/models/question_model.dart';
import 'package:cube_iii/core/constants/api_constants.dart';

void main() {
  group('Cube III Architecture Tests', () {
    test('QuestionModel serialization & deserialization', () {
      final q = QuestionModel(
        id: 'q_test_1',
        category: 'إسلاميات',
        questionText: 'سؤال تجريبي',
        options: ['أ', 'ب', 'ج', 'د'],
        correctAnswer: 'أ',
        explanation: 'شرح تجريبي',
      );

      final json = q.toJson();
      expect(json['category'], 'إسلاميات');
      expect(json['questionText'], 'سؤال تجريبي');
      expect(json['options'].length, 4);

      final fromJson = QuestionModel.fromMap('q_test_1', json);
      expect(fromJson.id, 'q_test_1');
      expect(fromJson.correctAnswer, 'أ');
    });

    test('Cloudflare API Constants point to Cube III Worker', () {
      expect(ApiConstants.baseUrl, contains('cube-iii-backend.workers.dev'));
      expect(ApiConstants.wsUrl, startsWith('wss://'));
      expect(ApiConstants.questions, contains('/api/questions'));
      expect(ApiConstants.users, contains('/api/users'));
      expect(ApiConstants.mediaUpload, contains('/api/media/upload'));
    });
  });
}
