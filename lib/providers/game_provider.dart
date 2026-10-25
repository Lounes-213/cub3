import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/firebase_service.dart';

class Team {
  String name;
  List<String> members;
  Color teamColor;

  Team({required this.name, required this.members, required this.teamColor});
}

class GameProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  Team? currentTeam;
  bool isSpectator = false;
  
  // Game State
  int score = 0;
  int currentQuestionIndex = 0;
  int totalQuestions = 0;
  List<QuestionModel> questions = [];
  
  // Point Distribution State
  int totalStars = 4;
  Map<String, int> distributedStars = {
    'A': 0,
    'B': 0,
    'C': 0,
    'D': 0,
  };
  
  // Current Question Data (cached from list)
  QuestionModel? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) return null;
    return questions[currentQuestionIndex];
  }

  GameProvider() {
    _initSync();
  }

  int questionStep = 0;
  int currentStageIndex = 0;
  Map<String, dynamic> realtimeChoices = {};
  Map<String, dynamic> teams = {};
  
  // Chrono & Trap State
  Map<String, dynamic> chrono = {
    'status': 'stopped',
    'remaining': 25,
    'duration': 25,
    'last_updated': 0,
  };
  bool hideVotes = false;
  Map<String, dynamic> activeTraps = {};
  Map<String, dynamic> trapUsage = {};

  List<QuestionModel> _allQuestionsBank = [];
  int _lastRefreshedStage = -1;
  DateTime? _lastBankRefreshAt;

  void _initSync() {
    // Listen to global bank first
    _firebaseService.getQuestionsStream().listen((updatedQuestions) {
      _allQuestionsBank = updatedQuestions;
      _updateCurrentStageQuestions();
    });

    _firebaseService.gameInfoStream.listen((info) {
      // تحليل كل حقل على حدة: خطأ في نوع حقل واحد ما يوقفش مزامنة الجولة.
      // active_traps يجي List من السيرفر وكان الـ cast لـ Map يرمي TypeError
      // قبل _syncQuestionsWithStage → اللاعب يبقى على سؤال الجولة السابقة
      // بينما يبان اسم الجولة الجديدة (إختلاف السؤال بين الأدمين واللاعب).
      try {
        if (info.containsKey('current_question_index')) {
          currentQuestionIndex = info['current_question_index'] ?? 0;
        }
        if (info.containsKey('question_step')) {
          questionStep = info['question_step'] ?? 0;
        }
        if (info.containsKey('hide_votes')) {
          hideVotes = info['hide_votes'] ?? false;
        }
        if (info.containsKey('chrono')) {
          chrono = Map<String, dynamic>.from(info['chrono'] as Map? ?? {});
        }
        if (info.containsKey('active_traps')) {
          activeTraps = _normalizeTraps(info['active_traps']);
        }
        if (info.containsKey('trap_usage')) {
          trapUsage = Map<String, dynamic>.from(info['trap_usage'] as Map? ?? {});
        }
      } catch (e) {
        debugPrint('gameInfo parse error: $e');
      }

      // Update questions based on stage
      try {
        final stages = info['stages'] as List? ?? [];
        final currentStageIdx = info['current_stage_index'] ?? 0;
        currentStageIndex = currentStageIdx;
        if (stages.isNotEmpty && currentStageIdx < stages.length) {
          // عند تبدل الجولة: نحدث بنك الأسئلة حتى يبان آخر نسخة مبرمجة من الأدمين
          // (وإلا بقا اللاعب عالق على نسخة قديمة من السؤال).
          if (currentStageIdx != _lastRefreshedStage) {
            _lastRefreshedStage = currentStageIdx;
            _refreshBankThrottled();
          }
          final stageQuestionsIds = List<String>.from(stages[currentStageIdx]['question_ids'] ?? []);
          _syncQuestionsWithStage(stageQuestionsIds);
        }
      } catch (e) {
        debugPrint('stage sync error: $e');
      }

      notifyListeners();
    });

    _firebaseService.realtimeChoicesStream.listen((choices) {
      realtimeChoices = choices;
      notifyListeners();
    });

    _firebaseService.teamsStream.listen((t) {
      teams = t;
      notifyListeners();
    });
  }

  /// السيرفر يخزّن active_traps كـ List (ويُحوّله أحياناً إلى Map) —
  /// نحوّله دايماً إلى Map موحّد حتى ما يرميش الـ cast ويقتل مزامنة الجولة.
  Map<String, dynamic> _normalizeTraps(dynamic raw) {
    if (raw is List) {
      final Map<String, dynamic> map = {};
      for (var i = 0; i < raw.length; i++) {
        map['trap_$i'] = raw[i];
      }
      return map;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  void _updateCurrentStageQuestions() {
    // Re-sync if bank updates
    _firebaseService.gameInfoStream.first.then((info) {
      final stages = info['stages'] as List? ?? [];
      final currentStageIdx = info['current_stage_index'] ?? 0;
      if (stages.isNotEmpty && currentStageIdx < stages.length) {
        final stageQuestionsIds = List<String>.from(stages[currentStageIdx]['question_ids'] ?? []);
        _syncQuestionsWithStage(stageQuestionsIds);
      }
    });
  }

  void _refreshBankThrottled() {
    final now = DateTime.now();
    if (_lastBankRefreshAt != null &&
        now.difference(_lastBankRefreshAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastBankRefreshAt = now;
    _firebaseService.refreshQuestions();
  }

  void _syncQuestionsWithStage(List<String> ids) {
    bool needsRefresh = _allQuestionsBank.isEmpty;

    // Map IDs to models in the EXACT order of the IDs list.
    // ما نحذفش أي سؤال ناقص: مكانو يبقى محجوز بسؤال مؤقت، وإلا تبدّل ترتيب
    // الفهارس ويعرض السؤال اللي بعده مكانو (يظهر سؤال آخر غير اللي برمج الأدمين).
    final sortedQuestions = <QuestionModel>[];
    for (var id in ids) {
      final bankIndex = _allQuestionsBank.indexWhere((element) => element.id == id);
      if (bankIndex >= 0) {
        sortedQuestions.add(_allQuestionsBank[bankIndex]);
      } else {
        needsRefresh = true;
        sortedQuestions.add(QuestionModel(
          id: id,
          questionText: 'جاري تحميل السؤال...',
          options: const [],
          correctAnswer: '',
          explanation: '',
          category: '',
        ));
      }
    }

    questions = sortedQuestions;
    totalQuestions = questions.length;

    // البنك فارغ أو ناقص (فشل الجلب الأول مثلاً) → نعيد المحاولة حتى يبان السؤال
    if (needsRefresh) {
      _refreshBankThrottled();
    }
    notifyListeners();
  }
  
  void setTeam(Team team) {
    currentTeam = team;
    notifyListeners();
  }

  void setSpectator(bool value) {
    isSpectator = value;
    notifyListeners();
  }

  // Distribution logic
  int get remainingStars {
    int used = distributedStars.values.fold(0, (sum, val) => sum + val);
    return totalStars - used;
  }

  void addStar(String option) {
    if (remainingStars > 0) {
      distributedStars[option] = (distributedStars[option] ?? 0) + 1;
      notifyListeners();
    }
  }

  void removeStar(String option) {
    if ((distributedStars[option] ?? 0) > 0) {
      distributedStars[option] = (distributedStars[option] ?? 0) - 1;
      notifyListeners();
    }
  }

  void resetStars() {
    distributedStars = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
    };
    notifyListeners();
  }

  /// Resets the user session completely (used when competition is closed)
  void resetSession() {
    currentTeam = null;
    isSpectator = false;
    score = 0;
    currentQuestionIndex = 0;
    totalQuestions = 0;
    questions = [];
    questionStep = 0;
    realtimeChoices = {};
    teams = {};
    chrono = {
      'status': 'stopped',
      'remaining': 25,
      'duration': 25,
      'last_updated': 0,
    };
    hideVotes = false;
    activeTraps = {};
    trapUsage = {};
    _lastRefreshedStage = -1;
    _lastBankRefreshAt = null;
    resetStars();
    notifyListeners();
  }
}
