import '../core/services/cloudflare_service.dart';
import '../models/question_model.dart';

/// Cloudflare Service Adapter (Preserves API compatibility for all UI screens)
/// Backend: Cloudflare D1 (Permanent Data), Cloudflare Durable Objects (Realtime), Cloudflare R2 (Media)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final CloudflareService _cf = CloudflareService();

  // ----------------------------------------------------
  // ADMIN FUNCTIONS (CLOUDFLARE D1)
  // ----------------------------------------------------

  Future<void> seedQuestions() => _cf.seedQuestions();
  Stream<List<QuestionModel>> getQuestionsStream() => _cf.getQuestionsStream();
  Future<List<QuestionModel>> getQuestionsOnce() => _cf.getQuestionsOnce();
  Future<void> refreshQuestions() => _cf.refreshQuestions();
  Future<void> addQuestion(QuestionModel question) => _cf.addQuestion(question);
  Future<void> updateQuestion(String key, QuestionModel question) => _cf.updateQuestion(key, question);
  Future<void> deleteQuestion(String key) => _cf.deleteQuestion(key);

  // ----------------------------------------------------
  // COMPETITION LIBRARY (CLOUDFLARE D1)
  // ----------------------------------------------------

  Future<void> saveToLibrary(String name, Map<String, dynamic> config) => _cf.saveToLibrary(name, config);
  Future<void> saveCompetition(String name, Map<String, dynamic> config) => _cf.saveCompetition(name, config);
  Future<void> deleteCompetitionFromLibrary(String name) => _cf.deleteCompetitionFromLibrary(name);
  Stream<Map<String, dynamic>> get competitionsLibraryStream => _cf.competitionsLibraryStream;

  // ----------------------------------------------------
  // REALTIME GAME STATE (CLOUDFLARE DURABLE OBJECTS)
  // ----------------------------------------------------

  Future<void> updateGameState({
    required String status,
    required int teamSize,
    required int numTeams,
    String? title,
    String? date,
    List<Map<String, dynamic>>? stages,
    String? creatorId,
    String? creatorName,
  }) =>
      _cf.updateGameState(
        status: status,
        teamSize: teamSize,
        numTeams: numTeams,
        title: title,
        date: date,
        stages: stages,
        creatorId: creatorId,
        creatorName: creatorName,
      );

  Future<void> updateGameSettings({
    String? title,
    String? date,
    int? numTeams,
    int? teamSize,
    String? adminId,
  }) =>
      _cf.updateGameSettings(
        title: title,
        date: date,
        numTeams: numTeams,
        teamSize: teamSize,
        adminId: adminId,
      );

  Future<void> updateGameInfoField(String key, dynamic value) => _cf.updateGameInfoField(key, value);

  Future<void> updateChrono({
    required String status,
    int? remaining,
    int? duration,
    String? adminId,
  }) =>
      _cf.updateChrono(
        status: status,
        remaining: remaining,
        duration: duration,
        adminId: adminId,
      );

  Future<Map<String, dynamic>?> getGameStateOnce() => _cf.getGameStateOnce();
  Future<void> pauseChrono([String? adminId]) => _cf.pauseChrono(adminId);
  Future<void> resumeChrono([String? adminId]) => _cf.resumeChrono(adminId);
  Future<void> pauseChronoOnReconnect() => _cf.pauseChronoOnReconnect();
  Future<void> deleteActiveCompetition([String? adminId]) => _cf.deleteActiveCompetition(adminId);
  Future<void> startGame([String? adminId]) => _cf.startGame(adminId);
  Future<void> finishGame({bool reveal = false}) => _cf.finishGame(reveal: reveal);
  Future<void> revealWinner() => _cf.revealWinner();
  Future<void> closeCompetition() => _cf.closeCompetition();
  Future<void> changeScreen(String screenName) => _cf.changeScreen(screenName);

  Future<void> setTeamChoice(String teamId, String choice) => _cf.setTeamChoice(teamId, choice);
  Future<void> clearRealtimeChoices() => _cf.clearRealtimeChoices();
  Stream<Map<String, dynamic>> get realtimeChoicesStream => _cf.realtimeChoicesStream;
  Future<Map<String, dynamic>> getRealtimeChoices() => _cf.getRealtimeChoices();

  Future<bool> useTrap({
    required String type,
    required String teamId,
    required String targetTeamId,
    required int questionIndex,
    String? fakeVote,
  }) =>
      _cf.useTrap(
        type: type,
        teamId: teamId,
        targetTeamId: targetTeamId,
        questionIndex: questionIndex,
        fakeVote: fakeVote,
      );

  Stream<Map<String, dynamic>> trapUsageStream(String teamId) => _cf.trapUsageStream(teamId);
  Stream<Map<String, dynamic>> get activeTrapsStream => _cf.activeTrapsStream;
  Stream<Map<String, dynamic>> get questionHistoryStream => _cf.questionHistoryStream;
  Future<void> clearActiveTraps() => _cf.clearActiveTraps();

  Future<void> scoreQuestion(String questionId, String correctAnswerLetter) =>
      _cf.scoreQuestion(questionId, correctAnswerLetter);

  Future<void> goToNextQuestion(int index) => _cf.goToNextQuestion(index);
  Future<void> goToNextStage(int stageIndex, String screenType) => _cf.goToNextStage(stageIndex, screenType);
  Future<void> setShowResults(bool show) => _cf.setShowResults(show);
  Future<void> setQuestionStep(int step) => _cf.setQuestionStep(step);

  // ----------------------------------------------------
  // TEAM/USER FUNCTIONS (CLOUDFLARE DURABLE OBJECTS)
  // ----------------------------------------------------

  Future<String> registerTeam(Map<String, dynamic> teamData) => _cf.registerTeam(teamData);
  Future<void> updateTeamSlot(String slotId, Map<String, dynamic> teamData) => _cf.updateTeamSlot(slotId, teamData);
  Future<void> removeTeam(String slotId) => _cf.removeTeam(slotId);
  Future<void> updateTeamScore(String slotId, int delta) => _cf.updateTeamScore(slotId, delta);
  Future<void> submitAnswer(String teamId, String stage, dynamic answerData) =>
      _cf.submitAnswer(teamId, stage, answerData);

  // ----------------------------------------------------
  // STREAMS FOR REAL-TIME SYNC
  // ----------------------------------------------------

  Stream<String> get screenStream => _cf.screenStream;
  Stream<Map<String, dynamic>> get gameInfoStream => _cf.gameInfoStream;
  Stream<Map<String, dynamic>> get teamsStream => _cf.teamsStream;

  // ----------------------------------------------------
  // PROFILE MANAGEMENT (CLOUDFLARE D1)
  // ----------------------------------------------------

  Future<void> seedDefaultProfiles() => _cf.seedDefaultProfiles();
  Future<Map<String, dynamic>?> getProfileByMatricule(String matricule) => _cf.getProfileByMatricule(matricule);
  Stream<Map<String, dynamic>?> getProfileByMatriculeStream(String matricule) =>
      _cf.getProfileByMatriculeStream(matricule);
  Future<Map<String, dynamic>?> getProfileByUsername(String username) => _cf.getProfileByUsername(username);
  Future<void> saveProfile(String matricule, Map<String, dynamic> profileData) =>
      _cf.saveProfile(matricule, profileData);
  Future<String?> getUserRole(String matricule) => _cf.getUserRole(matricule);
  Future<void> setUserRole(String matricule, String role) => _cf.setUserRole(matricule, role);
  Future<void> setProfileActive(String matricule, bool isActive) => _cf.setProfileActive(matricule, isActive);
  Stream<List<Map<String, dynamic>>> getProfilesStream() => _cf.getProfilesStream();
}
