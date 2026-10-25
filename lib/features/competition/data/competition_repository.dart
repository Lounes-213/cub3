import '../../../core/services/cloudflare_service.dart';
import '../../../models/question_model.dart';

abstract class ICompetitionRepository {
  Future<List<QuestionModel>> getQuestions();
  Stream<List<QuestionModel>> get questionsStream;
  Future<void> addQuestion(QuestionModel question);
  Future<void> updateQuestion(String id, QuestionModel question);
  Future<void> deleteQuestion(String id);

  Stream<Map<String, dynamic>> get gameStateStream;
  Stream<Map<String, dynamic>> get teamsStream;
  Stream<Map<String, dynamic>> get realtimeChoicesStream;

  Future<void> updateGameState({
    required String status,
    required int teamSize,
    required int numTeams,
    String? title,
    String? date,
    List<Map<String, dynamic>>? stages,
  });

  Future<void> setTeamChoice(String teamId, String choice);
  Future<void> scoreQuestion(String questionId, String correctAnswerLetter);
}

class CompetitionRepository implements ICompetitionRepository {
  final CloudflareService _cf = CloudflareService();

  @override
  Future<List<QuestionModel>> getQuestions() => _cf.getQuestionsOnce();

  @override
  Stream<List<QuestionModel>> get questionsStream => _cf.getQuestionsStream();

  @override
  Future<void> addQuestion(QuestionModel question) => _cf.addQuestion(question);

  @override
  Future<void> updateQuestion(String id, QuestionModel question) => _cf.updateQuestion(id, question);

  @override
  Future<void> deleteQuestion(String id) => _cf.deleteQuestion(id);

  @override
  Stream<Map<String, dynamic>> get gameStateStream => _cf.gameInfoStream;

  @override
  Stream<Map<String, dynamic>> get teamsStream => _cf.teamsStream;

  @override
  Stream<Map<String, dynamic>> get realtimeChoicesStream => _cf.realtimeChoicesStream;

  @override
  Future<void> updateGameState({
    required String status,
    required int teamSize,
    required int numTeams,
    String? title,
    String? date,
    List<Map<String, dynamic>>? stages,
  }) =>
      _cf.updateGameState(
        status: status,
        teamSize: teamSize,
        numTeams: numTeams,
        title: title,
        date: date,
        stages: stages,
      );

  @override
  Future<void> setTeamChoice(String teamId, String choice) => _cf.setTeamChoice(teamId, choice);

  @override
  Future<void> scoreQuestion(String questionId, String correctAnswerLetter) =>
      _cf.scoreQuestion(questionId, correctAnswerLetter);
}
