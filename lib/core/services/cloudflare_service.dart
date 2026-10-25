import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';
import '../../models/question_model.dart';
import '../../data/questions_bank.dart';

class CloudflareService {
  static final CloudflareService _instance = CloudflareService._internal();
  factory CloudflareService() => _instance;
  CloudflareService._internal() {
    _ws.connect();
    _initGameStateFetch();
  }

  final ApiClient _api = ApiClient();
  final WebSocketClient _ws = WebSocketClient();

  final StreamController<List<QuestionModel>> _questionsController =
      StreamController<List<QuestionModel>>.broadcast();

  final StreamController<Map<String, dynamic>> _libraryController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<List<Map<String, dynamic>>> _usersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  void _initGameStateFetch() async {
    try {
      final res = await _api.get(ApiConstants.gameState);
      if (res != null && res['state'] != null) {
        // Trigger initial state
      }
    } catch (_) {}

    // Initial fetch of questions and library
    refreshQuestions();
    refreshLibrary();
    refreshProfiles();
  }

  Future<Map<String, dynamic>?> getGameStateOnce() async {
    try {
      final res = await _api.get(ApiConstants.gameState);
      if (res != null && res['state'] != null) {
        return Map<String, dynamic>.from(res['state'] as Map);
      }
    } catch (_) {}
    if (_ws.currentState.isNotEmpty) {
      return _ws.currentState;
    }
    return null;
  }

  // ----------------------------------------------------
  // D1: QUESTIONS BANK
  // ----------------------------------------------------

  Future<void> seedQuestions() async {
    final list = QuestionsBank.allQuestions.map((q) => q.toJson()).toList();
    await _api.post(ApiConstants.questionsSeed, body: list);
    await refreshQuestions();
  }

  Future<List<QuestionModel>> getQuestionsOnce() async {
    try {
      final res = await _api.get(ApiConstants.questions);
      if (res != null && res['questions'] != null) {
        final list = (res['questions'] as List).map((q) {
          final map = Map<String, dynamic>.from(q as Map);
          return QuestionModel.fromMap(map['id'] ?? '', map);
        }).toList();
        return list;
      }
    } catch (e) {
      debugPrint('Error getting questions from D1: $e');
    }
    return [];
  }

  Stream<List<QuestionModel>> getQuestionsStream() {
    refreshQuestions();
    return _questionsController.stream;
  }

  Future<void> refreshQuestions() async {
    final questions = await getQuestionsOnce();
    _questionsController.add(questions);
  }

  Future<void> addQuestion(QuestionModel question) async {
    await _api.post(ApiConstants.questions, body: question.toJson());
    await refreshQuestions();
  }

  Future<void> updateQuestion(String key, QuestionModel question) async {
    final map = question.toJson();
    await _api.put('${ApiConstants.questions}/$key', body: map);
    await refreshQuestions();
  }

  Future<void> deleteQuestion(String key) async {
    await _api.delete('${ApiConstants.questions}/$key');
    await refreshQuestions();
  }

  // ----------------------------------------------------
  // D1: COMPETITIONS LIBRARY
  // ----------------------------------------------------

  Stream<Map<String, dynamic>> get competitionsLibraryStream {
    refreshLibrary();
    return _libraryController.stream;
  }

  Future<Map<String, dynamic>> getCompetitionsLibraryOnce() async {
    try {
      final res = await _api.get(ApiConstants.library);
      if (res != null && res['library'] != null) {
        return Map<String, dynamic>.from(res['library'] as Map);
      }
    } catch (e) {
      debugPrint('Error fetching library from D1: $e');
    }
    return {};
  }

  Future<void> refreshLibrary() async {
    final lib = await getCompetitionsLibraryOnce();
    _libraryController.add(lib);
  }

  Future<void> saveToLibrary(String name, Map<String, dynamic> config) async {
    await _api.post('${ApiConstants.library}/$name', body: config);
    await refreshLibrary();
  }

  Future<void> saveCompetition(String name, Map<String, dynamic> config) async {
    await saveToLibrary(name, config);
  }

  Future<void> deleteCompetitionFromLibrary(String name) async {
    await _api.delete('${ApiConstants.library}/$name');
    await refreshLibrary();
  }

  // ----------------------------------------------------
  // DURABLE OBJECTS: REALTIME GAME STATE & WEBSOCKETS
  // ----------------------------------------------------

  Stream<Map<String, dynamic>> get gameInfoStream {
    return _ws.stateStream.map((state) => state);
  }

  Stream<String> get screenStream {
    return _ws.stateStream.map((state) {
      return (state['current_screen'] as String?) ?? 'onboarding';
    });
  }

  Stream<Map<String, dynamic>> get teamsStream {
    return _ws.stateStream.map((state) {
      final teams = state['teams'];
      if (teams == null) return {};
      return Map<String, dynamic>.from(teams as Map);
    });
  }

  Stream<Map<String, dynamic>> get realtimeChoicesStream {
    return _ws.stateStream.map((state) {
      final choices = state['realtime_choices'];
      if (choices == null) return {};
      return Map<String, dynamic>.from(choices as Map);
    });
  }

  Stream<Map<String, dynamic>> trapUsageStream(String teamId) {
    return _ws.stateStream.map((state) {
      final allUsage = state['trap_usage'] as Map?;
      if (allUsage == null || allUsage[teamId] == null) return {};
      return Map<String, dynamic>.from(allUsage[teamId] as Map);
    });
  }

  Stream<Map<String, dynamic>> get activeTrapsStream {
    return _ws.stateStream.map((state) {
      final traps = state['active_traps'];
      if (traps == null) return {};
      if (traps is List) {
        final Map<String, dynamic> map = {};
        for (int i = 0; i < traps.length; i++) {
          map['trap_$i'] = traps[i];
        }
        return map;
      }
      return Map<String, dynamic>.from(traps as Map);
    });
  }

  Stream<Map<String, dynamic>> get questionHistoryStream {
    return _ws.stateStream.map((state) {
      final history = state['question_history'];
      if (history == null) return {};
      return Map<String, dynamic>.from(history as Map);
    });
  }

  Future<Map<String, dynamic>> getRealtimeChoices() async {
    final state = _ws.currentState;
    final choices = state['realtime_choices'];
    if (choices != null) return Map<String, dynamic>.from(choices as Map);
    return {};
  }

  Future<void> updateGameState({
    required String status,
    required int teamSize,
    required int numTeams,
    String? title,
    String? date,
    List<Map<String, dynamic>>? stages,
    String? creatorId,
    String? creatorName,
  }) async {
    await _ws.sendAction('update_game_state', {
      'status': status,
      'teamSize': teamSize,
      'numTeams': numTeams,
      'title': title,
      'date': date,
      'stages': stages,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'admin_id': creatorId,
      'admin_name': creatorName,
    });
  }

  Future<void> updateGameSettings({
    String? title,
    String? date,
    int? numTeams,
    int? teamSize,
    String? adminId,
  }) async {
    await _ws.sendAction('update_game_settings', {
      'title': ?title,
      'date': ?date,
      'numTeams': ?numTeams,
      'teamSize': ?teamSize,
      'admin_id': adminId,
    });
  }

  Future<void> updateGameInfoField(String key, dynamic value) async {
    await _ws.sendAction('update_game_info_field', {
      'key': key,
      'value': value,
    });
  }

  Future<void> updateChrono({
    required String status,
    int? remaining,
    int? duration,
    String? adminId,
  }) async {
    await _ws.sendAction('update_chrono', {
      'status': status,
      'remaining': ?remaining,
      'duration': ?duration,
      'admin_id': adminId,
    });
  }

  Future<void> pauseChrono([String? adminId]) async {
    await _ws.sendAction('pause_chrono', {'admin_id': adminId});
  }

  Future<void> resumeChrono([String? adminId]) async {
    await _ws.sendAction('resume_chrono', {'admin_id': adminId});
  }

  Future<void> pauseChronoOnReconnect() async {
    await _ws.sendAction('pause_chrono_on_reconnect');
  }

  Future<void> deleteActiveCompetition([String? adminId]) async {
    await _ws.sendAction('delete_active_competition', {'admin_id': adminId});
  }

  Future<void> startGame([String? adminId]) async {
    await _ws.sendAction('start_game', {'admin_id': adminId});
  }

  Future<void> finishGame({bool reveal = false}) async {
    await _ws.sendAction('finish_game', {'reveal': reveal});
  }

  Future<void> revealWinner() async {
    await _ws.sendAction('reveal_winner');
  }

  Future<void> closeCompetition() async {
    await _ws.sendAction('close_competition');
  }

  Future<void> changeScreen(String screenName) async {
    await _ws.sendAction('change_screen', {'screenName': screenName});
  }

  Future<void> setTeamChoice(String teamId, String choice) async {
    await _ws.sendAction('set_team_choice', {
      'teamId': teamId,
      'choice': choice,
    });
  }

  Future<void> clearRealtimeChoices() async {
    await _ws.sendAction('clear_realtime_choices');
  }

  Future<bool> useTrap({
    required String type,
    required String teamId,
    required String targetTeamId,
    required int questionIndex,
    String? fakeVote,
  }) async {
    await _ws.sendAction('use_trap', {
      'type': type,
      'teamId': teamId,
      'targetTeamId': targetTeamId,
      'questionIndex': questionIndex,
      'fakeVote': fakeVote,
    });
    return true;
  }

  Future<void> clearActiveTraps() async {
    await _ws.sendAction('clear_active_traps');
  }

  Future<void> scoreQuestion(String questionId, String correctAnswerLetter) async {
    await _ws.sendAction('score_question', {
      'questionId': questionId,
      'correctAnswerLetter': correctAnswerLetter,
    });
  }

  Future<void> goToNextQuestion(int index) async {
    await _ws.sendAction('go_to_next_question', {'index': index});
  }

  Future<void> goToNextStage(int stageIndex, String screenType) async {
    await _ws.sendAction('go_to_next_stage', {
      'stageIndex': stageIndex,
      'screenType': screenType,
    });
  }

  Future<void> setShowResults(bool show) async {
    await _ws.sendAction('set_show_results', {'show': show});
  }

  Future<void> setQuestionStep(int step) async {
    await _ws.sendAction('set_question_step', {'step': step});
  }

  Future<String> registerTeam(Map<String, dynamic> teamData) async {
    final slotId = teamData['id'] ?? 'team_1';
    await _ws.sendAction('update_team_slot', {
      'slotId': slotId,
      'teamData': teamData,
    });
    return slotId;
  }

  Future<void> updateTeamSlot(String slotId, Map<String, dynamic> teamData) async {
    await _ws.sendAction('update_team_slot', {
      'slotId': slotId,
      'teamData': teamData,
    });
  }

  Future<void> removeTeam(String slotId) async {
    await _ws.sendAction('remove_team', {'slotId': slotId});
  }

  Future<void> updateTeamScore(String slotId, int delta) async {
    await _ws.sendAction('update_team_score', {
      'slotId': slotId,
      'delta': delta,
    });
  }

  Future<void> submitAnswer(String teamId, String stage, dynamic answerData) async {
    await _ws.sendAction('submit_answer', {
      'teamId': teamId,
      'stage': stage,
      'answerData': answerData,
    });
  }

  // ----------------------------------------------------
  // D1: USERS & PROFILES
  // ----------------------------------------------------

  Future<void> seedDefaultProfiles() async {
    // Seeded automatically on Cloudflare D1
  }

  Future<Map<String, dynamic>?> getProfileByMatricule(String matricule) async {
    try {
      final res = await _api.get('${ApiConstants.userByMatricule}/$matricule');
      if (res != null && res['profile'] != null) {
        return Map<String, dynamic>.from(res['profile'] as Map);
      }
    } catch (_) {}
    return null;
  }

  Stream<Map<String, dynamic>?> getProfileByMatriculeStream(String matricule) {
    // Return periodic/stream value from D1
    final controller = StreamController<Map<String, dynamic>?>.broadcast();
    getProfileByMatricule(matricule).then((p) => controller.add(p));
    return controller.stream;
  }

  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      final res = await _api.get('${ApiConstants.userByUsername}/$username');
      if (res != null && res['profile'] != null) {
        return Map<String, dynamic>.from(res['profile'] as Map);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveProfile(String matricule, Map<String, dynamic> profileData) async {
    profileData['matricule'] = matricule;
    await _api.post(ApiConstants.users, body: profileData);
    await refreshProfiles();
  }

  Future<String?> getUserRole(String matricule) async {
    final profile = await getProfileByMatricule(matricule);
    return profile?['role'] as String?;
  }

  Future<void> setUserRole(String matricule, String role) async {
    await _api.put('${ApiConstants.users}/$matricule/role', body: {'role': role});
    await refreshProfiles();
  }

  Future<void> setProfileActive(String matricule, bool isActive) async {
    await _api.put('${ApiConstants.users}/$matricule/active', body: {'isActive': isActive});
    await refreshProfiles();
  }

  Stream<List<Map<String, dynamic>>> getProfilesStream() {
    refreshProfiles();
    return _usersController.stream;
  }

  Future<void> refreshProfiles() async {
    try {
      final res = await _api.get(ApiConstants.users);
      if (res != null && res['users'] != null) {
        final list = (res['users'] as List)
            .map((u) => Map<String, dynamic>.from(u as Map))
            .toList();
        _usersController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching users from D1: $e');
    }
  }

  // ----------------------------------------------------
  // R2: MEDIA STORAGE
  // ----------------------------------------------------

  Future<String?> uploadImageBase64(String base64Image, {String mime = 'image/jpeg'}) async {
    try {
      final res = await _api.post(ApiConstants.mediaUpload, body: {
        'base64': base64Image,
        'mime': mime,
      });
      if (res != null && res['url'] != null) {
        return res['url'] as String;
      }
    } catch (e) {
      debugPrint('Error uploading media to R2: $e');
    }
    return null;
  }
}
