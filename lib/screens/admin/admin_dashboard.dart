import 'dart:async';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/theme.dart';
import '../home_screen.dart';
import '../../services/firebase_service.dart';
import '../../models/question_model.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../arena_screen.dart';
import '../game_over_screen.dart';
import 'admin_qr_screen.dart';
import 'create_competition_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  Timer? _localTimer;
  Timer? _stageTimer;

  @override
  void initState() {
    super.initState();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _stageTimer?.cancel();
    super.dispose();
  }
  
  String _getStageName(String key) {
    switch (key) {
      case 'onboarding': return 'التسجيل';
      case 'fast_answer': return 'السرعة';
      case 'strategic_maneuver': return 'توزيع النقاط';
      case 'tunnel': return 'النفق';
      case 'direct_question': return 'سؤال مباشر';
      case 'who_am_i': return 'من أنا؟';
      case 'wager': return 'المجازفة';
      case 'leaderboard': return 'النتائج';
      case 'arena': return 'المواجهة';
      default: return key;
    }
  }

  int _getStageQuestionCount(Map<String, dynamic> gameData) {
    final stages = gameData['stages'] as List? ?? [];
    final currentStageIdx = gameData['current_stage_index'] ?? 0;
    if (currentStageIdx >= stages.length) return 0;
    final qIds = List<String>.from(stages[currentStageIdx]['question_ids'] ?? []);
    return qIds.length;
  }

  /// الإجابات المرسلة من الفرق للمرحلة الحالية (نص حر: من أنا؟ / سؤال مباشر /
  /// الرهان / النفق) — تُحفظ في حالة اللعبة تحت answers[نوع المرحلة][اسم الفريق].
  Map<String, String> _submittedAnswers(
      Map<String, dynamic> gameData, String stageType) {
    final answers = gameData['answers'];
    if (answers is! Map) return {};
    final forStage = answers[stageType];
    if (forStage is! Map) return {};

    final out = <String, String>{};
    forStage.forEach((team, data) {
      String text = '';
      if (data is Map) {
        if (data['answers'] is Map) {
          text = (data['answers'] as Map).values.join('  |  ');
        } else if (data['answer_1'] != null || data['answer_2'] != null) {
          text = [data['answer_1'], data['answer_2']]
              .where((v) => v != null && v.toString().trim().isNotEmpty)
              .join('  |  ');
        } else if (data['answer'] != null) {
          text = data['answer'].toString();
        }
        final wager = data['wager_percentage'];
        if (wager is num && wager > 0) {
          text = 'رهان ${(wager * 100).round()}% — $text';
        }
        final hint = data['hint_level'];
        if (hint is num && hint > 0) {
          text = '$text  (لمحة $hint)';
        }
      } else if (data != null) {
        text = data.toString();
      }
      if (text.trim().isNotEmpty) {
        out[team.toString()] = text.trim();
      }
    });
    return out;
  }

  Widget _answerRow(String team, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 16, color: AppColor.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(answer,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goForward(Map<String, dynamic> gameData, List<QuestionModel> questions) async {
    final currentStep = gameData['question_step'] ?? 0;
    final stages = gameData['stages'] as List? ?? [];
    final currentStageIdx = gameData['current_stage_index'] ?? 0;
    final currentQIndex = gameData['current_question_index'] ?? 0;
    final totalQs = _getStageQuestionCount(gameData);

    // Get current question for scoring
    QuestionModel? currentQ;
    if (currentStageIdx < stages.length) {
      final qIds = List<String>.from(stages[currentStageIdx]['question_ids'] ?? []);
      if (currentQIndex < qIds.length) {
        final qId = qIds[currentQIndex];
        currentQ = questions.firstWhere((q) => q.id == qId, 
          orElse: () => QuestionModel(id: '', questionText: '', options: [], correctAnswer: '', category: '', explanation: ''));
      }
    }

    if (currentStep == -2) {
      // Welcome → Stage Intro
      _stageTimer?.cancel();
      await _firebaseService.setQuestionStep(-1);
      _stageTimer = Timer(const Duration(seconds: 5), () async {
        if (mounted) await _firebaseService.setQuestionStep(0);
      });
    } else if (currentStep == -1) {
      // Stage Intro → Question (Manual override of the 5 second timer)
      _stageTimer?.cancel();
      await _firebaseService.setQuestionStep(0);
    } else if (currentStep == 0) {
      // Question → Options + auto chrono
      await _firebaseService.setQuestionStep(1);
      await _firebaseService.updateChrono(status: 'running', remaining: 25, duration: 25);
    } else if (currentStep == 1) {
      // Manual advance while paused or forced
      await _firebaseService.updateChrono(status: 'stopped', remaining: 0);
      if (currentQ != null && (currentQ.id ?? '').isNotEmpty) {
        final letterIndex = currentQ.options.indexOf(currentQ.correctAnswer);
        if (letterIndex >= 0) {
          final correctLetter = String.fromCharCode(65 + letterIndex);
          await _firebaseService.scoreQuestion(currentQ.id ?? '', correctLetter);
        }
      }
      await _firebaseService.setQuestionStep(2);
    } else if (currentStep == 2) {
      // Team Votes → Correct Answer (score the question)
      // Note: Auto-scoring now also happens in `scoreQuestion` if timer ends naturally,
      // but if the admin manually advances from 2 to 3, we ensure it's scored.
      if (currentQ != null && (currentQ.id ?? '').isNotEmpty) {
        final letterIndex = currentQ.options.indexOf(currentQ.correctAnswer);
        if (letterIndex >= 0) {
          final correctLetter = String.fromCharCode(65 + letterIndex);
          await _firebaseService.scoreQuestion(currentQ.id ?? '', correctLetter);
        }
      }
      await _firebaseService.setQuestionStep(3);
    } else if (currentStep == 3) {
      // Correct Answer → Explanation
      await _firebaseService.setQuestionStep(4);
    } else if (currentStep == 4) {
      // Explanation → Logos
      await _firebaseService.setQuestionStep(5);
    } else if (currentStep == 5) {
      // Logos → Next question or next stage or finish
      _stageTimer?.cancel();
      if (currentQIndex < totalQs - 1) {
        // More questions in this stage → next question (Atomic)
        await _firebaseService.goToNextQuestion(currentQIndex + 1);
      } else if (currentStageIdx < stages.length - 1) {
        // Last question but more stages → next stage intro (Atomic)
        final nextIdx = currentStageIdx + 1;
        final nextStage = stages[nextIdx];
        await _firebaseService.goToNextStage(nextIdx, nextStage['type']);
        
        // Stage intro is set to -1. Wait 5 seconds and transition to step 0 automatically!
        _stageTimer = Timer(const Duration(seconds: 5), () async {
          if (mounted) await _firebaseService.setQuestionStep(0);
        });
      } else {
        // Last question of last stage → finish
        await _firebaseService.finishGame();
      }
    }
    // Step 1 is blocked (chrono running) — auto-advances to 2 when chrono ends
  }

  Future<void> _goBack(Map<String, dynamic> gameData) async {
    _stageTimer?.cancel();
    final currentStep = gameData['question_step'] ?? 0;
    final currentQIndex = gameData['current_question_index'] ?? 0;

    if (currentStep > -2) {
      // If going back from step 1, stop chrono
      if (currentStep == 1) {
        await _firebaseService.updateChrono(status: 'stopped', remaining: 25, duration: 25);
      }
      // If at step 0 and not first question, go to previous question logos step
      if (currentStep == 0 && currentQIndex > 0) {
        await _firebaseService.goToNextQuestion(currentQIndex - 1);
        await _firebaseService.setQuestionStep(5);
      } else if (currentStep == 0 && currentQIndex == 0) {
        // First question of stage → go back to stage intro
        await _firebaseService.setQuestionStep(-1);
      } else {
        await _firebaseService.setQuestionStep(currentStep - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: _firebaseService.getQuestionsStream(),
      builder: (context, qSnapshot) {
        final questions = qSnapshot.data ?? [];

        return StreamBuilder<Map<String, dynamic>>(
          stream: _firebaseService.gameInfoStream,
          builder: (context, gameSnapshot) {
            final gameData = gameSnapshot.data ?? {};
            final status = gameData['status'] ?? 'none';

            final userProvider = context.watch<UserProvider>();
            final myMatricule = userProvider.matricule.isNotEmpty ? userProvider.matricule : 'admin';
            final creatorId = gameData['creator_id'];
            final creatorName = gameData['creator_name'] ?? 'مشرف آخر';
            final isOwner = creatorId == null || creatorId == myMatricule || creatorId == 'admin';

            return Scaffold(
              appBar: GlassAppBar(
                title: Text(
                  gameData['title'] != null && gameData['title'].toString().isNotEmpty
                      ? 'مركز العمليات — ${gameData['title']}'
                      : 'مركز العمليات',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  tooltip: 'رجوع',
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: 'عرض واجهة المواجهات الحية',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArenaScreen()),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (!isOwner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.amber.withValues(alpha: 0.2),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ هذه المسابقة خاصة بالمشرف: $creatorName. يمكنك المتابعة فقط.',
                              style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _buildBody(status, gameData, questions, isOwner, myMatricule),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    String status,
    Map<String, dynamic> gameData,
    List<QuestionModel> questions,
    bool isOwner,
    String currentAdminMatricule,
  ) {
    if (status == 'none') {
      return _buildEmptyState();
    }
    if (status == 'finished') {
      return _buildFinishedContent(gameData, isOwner);
    }
    if (status == 'waiting') {
      return _buildWaitingManagement(context, gameData, isOwner, currentAdminMatricule);
    }
    return _buildActiveCompetitionContent(questions, gameData, isOwner, currentAdminMatricule);
  }

  /// شاشة ما بعد النهاية: النتائج النهائية + الكشف عن الفائز + الإغلاق
  /// (بدل ما نعرض "لا توجد مسابقة" والنتائج تضيع من الأدمين).
  Widget _buildFinishedContent(Map<String, dynamic> gameData, bool isOwner) {
    final revealed = gameData['reveal_winner'] == true;
    final teamsMap = Map<String, dynamic>.from(gameData['teams'] as Map? ?? {});
    final ranking = teamsMap.values
        .where((t) => t is Map && t['is_registered'] == true)
        .toList()
      ..sort((a, b) => ((b['score'] ?? 0) as num).compareTo((a['score'] ?? 0) as num));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.primaryColor,
                  AppColor.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 54, color: Colors.amber),
                const SizedBox(height: 12),
                Text(
                  gameData['title']?.toString().isNotEmpty == true
                      ? gameData['title'].toString()
                      : 'المسابقة',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'انتهت المسابقة — هذه النتائج النهائية',
                  style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'الترتيب النهائي',
            icon: Icons.leaderboard,
            child: ranking.isEmpty
                ? const Text('لا توجد فرق مسجلة',
                    style: TextStyle(color: Colors.white54))
                : Column(
                    children: [
                      for (int i = 0; i < ranking.length; i++)
                        _finalRankRow(ranking[i], i),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isOwner && !revealed) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _firebaseService.revealWinner(),
                    icon: const Icon(Icons.visibility),
                    label: const Text('كشف الفائز',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameOverScreen()),
                  ),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('معاينة شاشة النتائج'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: AppColor.primaryColor.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('إغلاق المسابقة'),
                    content: const Text(
                        'سيتم إغلاق المسابقة وحفظ نتائجها في السجل وإرجاع الجميع إلى شاشة التسجيل.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('إغلاق المسابقة',
                            style: TextStyle(color: Colors.orangeAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await _firebaseService.closeCompetition();
              },
              icon: const Icon(Icons.close, color: Colors.orangeAccent),
              label: const Text('إغلاق المسابقة وحفظها في السجل',
                  style: TextStyle(color: Colors.orangeAccent)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _finalRankRow(dynamic team, int index) {
    const medalColors = [
      Colors.amber,
      Color(0xFFBDBDBD),
      Color(0xFFCD7F32),
    ];
    final rawColor = team['color'];
    final colorInt = rawColor is int
        ? rawColor
        : int.tryParse(rawColor?.toString() ?? '') ?? 0xFFFFFFFF;
    final color = Color(colorInt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: index < 3
            ? Border.all(color: medalColors[index].withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          index < 3
              ? Icon(Icons.emoji_events, size: 22, color: medalColors[index])
              : Text('#${index + 1}',
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              team['name']?.toString() ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${team['score'] ?? 0} نقطة',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard_customize, size: 80, color: Colors.white10),
          const SizedBox(height: 24),
          const Text('لا توجد مسابقة جارية حالياً', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white38)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCompetitionScreen())),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء مسابقة جديدة الآن'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showLibraryDialog(context),
            icon: const Icon(Icons.library_books),
            label: const Text('المسابقات المحفوظة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              side: BorderSide(color: AppColor.primaryColor.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingManagement(BuildContext context, Map<String, dynamic> gameData, bool isOwner, String currentAdminMatricule) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.teamsStream,
      builder: (context, snapshot) {
        final teamsMap = snapshot.data ?? {};
        final registeredTeams = teamsMap.entries.where((e) => e.value['is_registered'] == true).toList();
        final maxTeams = gameData['num_teams'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                title: 'إدارة قاعة الانتظار',
                icon: Icons.hourglass_empty,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الفرق: ${registeredTeams.length} / $maxTeams',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminQRScreen(numTeams: maxTeams))),
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('إظهار الأكواد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (registeredTeams.isEmpty)
                      const Center(child: Text('لا توجد فرق منضمة بعد', style: TextStyle(color: Colors.white24)))
                    else
                      Column(
                        children: registeredTeams.map((entry) {
                          final team = entry.value;
                          final color = Color(int.parse(team['color']?.toString() ?? '0xFFFFFFFF'));
                          return Card(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: color, radius: 10),
                              title: Text(team['name'] ?? ''),
                              subtitle: Text('${team['members']?.length ?? 0} أعضاء'),
                              trailing: isOwner
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                      onPressed: () => _firebaseService.removeTeam(entry.key),
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: (isOwner && registeredTeams.isNotEmpty)
                    ? () => _firebaseService.startGame(currentAdminMatricule)
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(isOwner ? 'بدء المسابقة الآن' : 'المسابقة خاصة بمشرف آخر'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: AppColor.correctColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveCompetitionContent(
    List<QuestionModel> questions,
    Map<String, dynamic> gameData,
    bool isOwner,
    String currentAdminMatricule,
  ) {
    final currentQIndex = gameData['current_question_index'] ?? 0;
    final showResults = gameData['show_results'] ?? false;
    final stages = gameData['stages'] as List? ?? [];
    final currentStageIdx = gameData['current_stage_index'] ?? 0;
    final stageName = currentStageIdx < stages.length ? stages[currentStageIdx]['name'] : 'نهاية المسابقة';
    final stageType = currentStageIdx < stages.length ? stages[currentStageIdx]['type'] : 'finished';

    QuestionModel? currentQ;
    if (currentStageIdx < stages.length) {
      final qIds = List<String>.from(stages[currentStageIdx]['question_ids'] ?? []);
      if (currentQIndex < qIds.length) {
        final qId = qIds[currentQIndex];
        currentQ = questions.firstWhere((q) => q.id == qId, orElse: () => QuestionModel(id: '', questionText: '', options: [], correctAnswer: '', category: '', explanation: ''));
      }
    }

    final chronoData = Map<String, dynamic>.from(gameData['chrono'] as Map? ?? {});
    final chronoStatus = chronoData['status'] ?? 'stopped';
    final remaining = _computeRemainingSeconds(chronoData);
    final currentStep = gameData['question_step'] ?? 0;
    final isChronoRunning = chronoStatus == 'running' && remaining > 0;

    if (chronoStatus == 'running' && remaining == 0 && currentStep == 1 && currentQ != null) {
      final targetQ = currentQ;
      Future.microtask(() async {
        final letterIndex = targetQ.options.indexOf(targetQ.correctAnswer);
        if (letterIndex >= 0) {
          final correctLetter = String.fromCharCode(65 + letterIndex);
          await _firebaseService.scoreQuestion(targetQ.id ?? '', correctLetter);
        }
        await _firebaseService.setQuestionStep(2);
        await _firebaseService.updateChrono(status: 'stopped', remaining: 0);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Stage Prominent Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.primaryColor, AppColor.primaryColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColor.primaryColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                const Text('المرحلة الحالية', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(stageName.toUpperCase(), 
                  style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
                  child: Text(_getStageName(stageType), style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 24),
          
          if (_submittedAnswers(gameData, stageType).isNotEmpty) ...[
            _buildSection(
              title: 'الإجابات المرسلة من الفرق',
              icon: Icons.edit_note,
              child: Column(
                children: _submittedAnswers(gameData, stageType)
                    .entries
                    .map((e) => _answerRow(e.key, e.value))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildSection(
            title: 'التحكم في البث المباشر',
            icon: Icons.live_tv,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إظهار النتائج للجميع', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: showResults,
                      activeThumbColor: AppColor.primaryColor,
                      onChanged: (val) => _firebaseService.setShowResults(val),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إخفاء تصويتات الفرق على الخيارات', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: gameData['hide_votes'] ?? false,
                      activeThumbColor: AppColor.primaryColor,
                      onChanged: (val) => _firebaseService.updateGameInfoField('hide_votes', val),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white10),
                // Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getStepLabel(currentStep),
                        style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 16, color: Colors.white24),
                      const SizedBox(width: 12),
                      Text(
                        'سؤال ${currentQIndex + 1} / ${_getStageQuestionCount(gameData)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Current Question Preview
                _buildQuestionPreview(questions, gameData, currentQIndex),
                const SizedBox(height: 16),
                // Timer & Pause/Resume Control
                if (currentStep == 1 || isChronoRunning || chronoStatus == 'paused')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: chronoStatus == 'paused'
                          ? Colors.amber.withValues(alpha: 0.15)
                          : (remaining <= 10
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : AppColor.primaryColor.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: chronoStatus == 'paused'
                            ? Colors.amber
                            : (remaining <= 10
                                ? Colors.redAccent
                                : AppColor.primaryColor.withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          chronoStatus == 'paused'
                              ? Icons.pause_circle_filled
                              : Icons.timer,
                          color: chronoStatus == 'paused' ? Colors.amber : AppColor.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chronoStatus == 'paused' ? 'المؤقت موقوف مؤقتاً' : 'الوقت المتبقي',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: chronoStatus == 'paused' ? Colors.amber : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$remaining ثانية',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: remaining <= 10 ? Colors.redAccent : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isOwner && chronoStatus == 'running')
                          ElevatedButton.icon(
                            onPressed: () => _firebaseService.pauseChrono(currentAdminMatricule),
                            icon: const Icon(Icons.pause, size: 16),
                            label: const Text('إيقاف مؤقت'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        else if (isOwner && chronoStatus == 'paused')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _firebaseService.updateChrono(
                                    status: 'paused',
                                    remaining: remaining + 10,
                                    adminId: currentAdminMatricule,
                                  );
                                },
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('+10ث'),
                                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                onPressed: () => _firebaseService.resumeChrono(currentAdminMatricule),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('استئناف الوقت'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.correctColor,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                // Forward / Back buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: (!isOwner || isChronoRunning || currentStep <= -2) ? null : () => _goBack(gameData),
                          icon: const Icon(Icons.arrow_back_rounded, size: 22),
                          label: const Text('قبض', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.03),
                            disabledForegroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: (!isOwner || isChronoRunning) ? null : () => _goForward(gameData, questions),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                          label: Text(
                            currentStep == 5 
                              ? (currentQIndex < _getStageQuestionCount(gameData) - 1 
                                  ? 'السؤال التالي ➜' 
                                  : 'المرحلة التالية ➜')
                              : 'بعد ➜',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primaryColor,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: AppColor.primaryColor.withValues(alpha: 0.15),
                            disabledForegroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'ترتيب الفرق (تحكم يدوي)',
            icon: Icons.edit_note,
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _firebaseService.teamsStream,
              builder: (context, snapshot) {
                final teamsMap = snapshot.data ?? {};
                final registeredTeams = teamsMap.entries.where((e) => e.value['is_registered'] == true).toList();
                registeredTeams.sort((a, b) => (b.value['score'] ?? 0).compareTo(a.value['score'] ?? 0));
                
                return Column(
                  children: registeredTeams.map((entry) {
                    final team = entry.value;
                    final color = Color(int.parse(team['color']?.toString() ?? '0xFFFFFFFF'));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: color, radius: 10),
                          const SizedBox(width: 12),
                          Expanded(child: Text(team['name'] ?? '')),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: isOwner ? () => _firebaseService.updateTeamScore(entry.key, -1) : null,
                          ),
                          Text('${team['score'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: isOwner ? () => _firebaseService.updateTeamScore(entry.key, 1) : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          if (isOwner) ...[
            ElevatedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('إنهاء المسابقة كلياً؟'),
                    content: const Text('سيتم عرض شاشة الفوز النهائية للجميع وسيتم إيقاف التفاعل.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد الإنهاء')),
                    ],
                  ),
                );
                if (confirm == true) await _firebaseService.finishGame(reveal: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.wrongColor,
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Text('إعلان النتائج النهائية وإنهاء الحدث'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('إغلاق المسابقة'),
                    content: const Text('سيتم إغلاق المسابقة وإرجاع جميع المستخدمين إلى شاشة التسجيل.\nيمكنك بعدها إنشاء مسابقة جديدة.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('إغلاق المسابقة', style: TextStyle(color: Colors.orangeAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await _firebaseService.closeCompetition();
              },
              icon: const Icon(Icons.close, color: Colors.orangeAccent),
              label: const Text('إغلاق المسابقة وتجهيز واحدة جديدة', style: TextStyle(color: Colors.orangeAccent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLibraryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مكتبة المسابقات'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _firebaseService.competitionsLibraryStream,
            builder: (context, snapshot) {
              final library = snapshot.data ?? {};
              if (library.isEmpty) return const Center(child: Text('المكتبة فارغة حالياً'));
              
              return ListView(
                children: library.entries.map((e) => ListTile(
                  title: Text(e.key),
                  subtitle: Text('${(e.value['stages'] as List?)?.length ?? 0} مراحل'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColor.primaryColor, size: 20),
                        tooltip: 'تعديل',
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CreateCompetitionScreen(
                              existingData: Map<String, dynamic>.from(e.value),
                              existingKey: e.key,
                            ),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        tooltip: 'حذف',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('حذف المسابقة؟'),
                              content: const Text('هل أنت متأكد أنك تريد حذف هذه المسابقة من المكتبة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد الحذف')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _firebaseService.deleteCompetitionFromLibrary(e.key);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    final userProvider = context.read<UserProvider>();
                    final creatorId = userProvider.matricule.isNotEmpty
                        ? userProvider.matricule
                        : 'admin';
                    final creatorName = userProvider.fullNameAr.isNotEmpty
                        ? userProvider.fullNameAr
                        : 'مشرف';
                    await _firebaseService.updateGameState(
                      status: 'waiting',
                      numTeams: e.value['num_teams'],
                      teamSize: e.value['team_size'],
                      title: e.value['title'],
                      date: e.value['date'],
                      stages: (e.value['stages'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList(),
                      creatorId: creatorId,
                      creatorName: creatorName,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                )).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPreview(List<QuestionModel> questions, Map<String, dynamic> gameData, int currentQIndex) {
    final stages = gameData['stages'] as List? ?? [];
    final currentStageIdx = gameData['current_stage_index'] ?? 0;
    if (currentStageIdx >= stages.length) return const SizedBox();
    
    final stage = stages[currentStageIdx];
    final qIds = List<String>.from(stage['question_ids'] ?? []);
    if (currentQIndex >= qIds.length) return const Center(child: Text('انتهت الأسئلة في هذه المرحلة', style: TextStyle(color: Colors.white24)));
    
    final qId = qIds[currentQIndex];
    final question = questions.firstWhere((q) => q.id == qId, orElse: () => QuestionModel(id: '', questionText: 'السؤال غير موجود', options: [], correctAnswer: '', category: '', explanation: ''));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.questionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...question.options.map((opt) {
            final isCorrect = opt == question.correctAnswer;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect ? AppColor.correctColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCorrect ? AppColor.correctColor : Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isCorrect ? AppColor.correctColor : Colors.white24),
                  const SizedBox(width: 10),
                  Text(opt, style: TextStyle(color: isCorrect ? AppColor.correctColor : Colors.white70, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case -2: return '🏠 الترحيب';
      case -1: return '🏷️ اسم المرحلة';
      case 0: return '❓ السؤال';
      case 1: return '⏱️ الخيارات + المؤقت';
      case 2: return '👥 عرض إجابات الفرق';
      case 3: return '✅ الإجابة الصحيحة';
      case 4: return '📝 الشرح';
      case 5: return '🎨 اللوغو';
      default: return 'خطوة $step';
    }
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColor.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
                  child,
        ],
      ),
    );
  }



  int _computeRemainingSeconds(Map<String, dynamic> chronoData) {
    final status = chronoData['status'] ?? 'stopped';
    final duration = chronoData['duration'] ?? 25;
    final remaining = chronoData['remaining'] ?? duration;
    final lastUpdated = chronoData['last_updated'] ?? 0;

    if (status == 'running') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = (now - lastUpdated) / 1000;
      final currentRemaining = (remaining - elapsed).floor();
      return currentRemaining < 0 ? 0 : currentRemaining;
    }
    return remaining;
  }
}
