import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../../theme/theme.dart';
import '../../services/firebase_service.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedOption;
  Timer? _localTimer;
  int? _lastQuestionIndex;

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
    super.dispose();
  }

  void _selectOption(String choice) {
    final gameProvider = context.read<GameProvider>();
    if (gameProvider.isSpectator) return;
    if (gameProvider.questionStep > 1) return;

    // Prevent changing answer if chronometer has ended!
    final remaining = _computeRemainingSeconds(gameProvider.chrono);
    if (remaining <= 0) return;

    setState(() => _selectedOption = choice);

    if (gameProvider.currentTeam != null) {
      _firebaseService.setTeamChoice(gameProvider.currentTeam!.name, choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameProvider = context.watch<GameProvider>();
    final teamColor =
        gameProvider.currentTeam?.teamColor ?? theme.colorScheme.primary;
    final step = gameProvider.questionStep;
    final question = gameProvider.currentQuestion;

    // Reset local selection when question changes!
    final currentQIndex = gameProvider.currentQuestionIndex;
    if (_lastQuestionIndex != currentQIndex) {
      _lastQuestionIndex = currentQIndex;
      _selectedOption = null;
    }

    // بعد إعادة الاتصال: نرجّع نفس الجواب اللي اختاره الفريق من السيرفر
    // حتى يرجع اللاعب لنفس البلاصة بالضبط (الاختيارات محفوظة في الحالة).
    if (_selectedOption == null && step <= 2 && !gameProvider.isSpectator) {
      final teamName = gameProvider.currentTeam?.name;
      if (teamName != null) {
        final saved = gameProvider.realtimeChoices[teamName];
        if (saved is String && saved.isNotEmpty && saved.length <= 3) {
          _selectedOption = saved;
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _firebaseService.gameInfoStream,
          builder: (context, snapshot) {
            final gameData = snapshot.data ?? {};
            final showResults = gameData['show_results'] ?? false;

            if (showResults) {
              return _buildFullPageLeaderboard(theme, gameProvider);
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                if (isWide && gameProvider.isSpectator) {
                  return _buildWideSpectatorView(
                    theme,
                    gameProvider,
                    step,
                    question,
                    showResults,
                    gameData,
                  );
                }

                return _buildMobileView(
                  theme,
                  gameProvider,
                  teamColor,
                  step,
                  question,
                  showResults,
                  gameData,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileView(
    ThemeData theme,
    GameProvider gameProvider,
    Color teamColor,
    int step,
    dynamic question,
    bool showResults,
    Map<String, dynamic> gameData,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(theme, gameProvider, teamColor),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildDynamicContent(
                      theme,
                      gameProvider,
                      teamColor,
                      step,
                      question,
                      false,
                      gameData,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideSpectatorView(
    ThemeData theme,
    GameProvider gameProvider,
    int step,
    dynamic question,
    bool showResults,
    Map<String, dynamic> gameData,
  ) {
    final teams = gameProvider.teams.values
        .where((t) => t['is_registered'] == true)
        .toList();
    teams.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    final int topScore = teams.isNotEmpty
        ? ((teams.first['score'] ?? 0) as int).clamp(1, 1 << 31 - 1)
        : 1;

    return Row(
      children: [
        AnimatedContainer(
          duration: 600.ms,
          curve: Curves.easeOutQuart,
          width: showResults ? 420 : 0,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColor.surfaceColor,
                theme.colorScheme.surface.withValues(alpha: 0.6),
              ],
            ),
            border: Border(
              left: BorderSide(
                color: AppColor.primaryColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFFFB800),
                          Color(0xFFFF9800),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'لوحة الترتيب',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'مباشر خلال المسابقة',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColor.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12, thickness: 1),
                const SizedBox(height: 20),
                ...teams.asMap().entries.map((entry) {
                  final index = entry.key;
                  final team = entry.value;
                  final color = Color(
                    int.parse(team['color']?.toString() ?? '0xFFFFFFFF'),
                  );
                  final iconCode =
                      team['icon_code'] as int? ?? Icons.person.codePoint;
                  final score = team['score'] ?? 0;
                  final double ratio = topScore == 0 ? 0 : (score / topScore).clamp(0, 1);
                  Color rankBadgeColor = Colors.white12;
                  Color rankTextColor = Colors.white;
                  IconData? rankIcon;
                  if (index == 0) {
                    rankBadgeColor = const Color(0xFFFFB800);
                    rankTextColor = Colors.black;
                    rankIcon = Icons.looks_one_rounded;
                  } else if (index == 1) {
                    rankBadgeColor = const Color(0xFFBDBDBD);
                    rankTextColor = Colors.black;
                    rankIcon = Icons.looks_two_rounded;
                  } else if (index == 2) {
                    rankBadgeColor = const Color(0xFFCD7F32);
                    rankTextColor = Colors.white;
                    rankIcon = Icons.looks_3_rounded;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: rankBadgeColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    if (index < 3)
                                      BoxShadow(
                                        color: rankBadgeColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: rankIcon != null
                                    ? Icon(rankIcon,
                                        color: rankTextColor, size: 16)
                                    : Text('${index + 1}',
                                        style: TextStyle(
                                          color: rankTextColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        )),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.3)),
                                ),
                                child: Icon(
                                  IconHelper.getIconFromCode(iconCode,
                                      fallback: Icons.person),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  team['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.25),
                                      color.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  '${score} ن',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                height: 5,
                                width: double.infinity,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio < 0.03 ? 0.03 : ratio,
                                alignment: Alignment.centerRight,
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideX(begin: -0.2, end: 0, delay: (40 * index).ms).fadeIn(delay: (40 * index).ms);
                }),
              ],
            ),
          ),
        ),

        Expanded(
          child: Column(
            children: [
              _buildHeader(theme, gameProvider, theme.colorScheme.primary),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(60),
                    child: _buildDynamicContent(
                      theme,
                      gameProvider,
                      theme.colorScheme.primary,
                      step,
                      question,
                      true,
                      gameData,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicContent(
    ThemeData theme,
    GameProvider gameProvider,
    Color teamColor,
    int step,
    dynamic question,
    bool isWide,
    Map<String, dynamic> gameData,
  ) {
    // Step -2: Welcome & Organiser Logos Screen
    if (step == -2) return _buildWelcomeScreen(theme, isWide);

    // Step -1: Stage Name Introduction Screen
    if (step == -1) return _buildStageIntroScreen(theme, gameData, isWide);

    // Phase 5: Logos
    if (step == 5) return _buildLogosPhase(theme, isWide);

    // السؤال ما وصلش بعد (بنك الأسئلة لم يُجلب) → شاشة تحميل بدل شاشة فارغة
    if (question == null) return _buildQuestionLoading(theme);

    // Freeze check for my team
    final myTeamId = gameProvider.currentTeam?.name;
    final isMeFrozen =
        myTeamId != null && _isTeamFrozen(myTeamId, gameProvider);

    if (isMeFrozen && step < 2) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.ac_unit,
                size: 80,
                color: Colors.blueAccent,
              ).animate().scale().shimmer(),
              const SizedBox(height: 24),
              const Text(
                '🥶 لقد تم تجميدك!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'لا يمكنك الإجابة على هذا السؤال بسبب فخ التجميد النشط ضدك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    // Unified Phase 0-3 layout
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question: Centered in Step 0, scaled down if Step >= 1
        AnimatedContainer(
          duration: 800.ms,
          curve: Curves.easeOutBack,
          padding: EdgeInsets.only(bottom: step == 0 ? 0 : 20),
          child: _buildQuestionSection(
            theme,
            question,
            isWide: isWide,
            isCentered: step == 0,
            isMini: step >= 1,
          ),
        ),

        // Team Answer Status: Correct, Wrong, or Unanswered (Step 3+)
        if (step >= 3 && !gameProvider.isSpectator && myTeamId != null) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final myChoiceLetter = gameProvider.realtimeChoices[myTeamId];
              final correctAnswerIndex =
                  question.options.indexOf(question.correctAnswer) as int;
              final correctAnswerLetter = correctAnswerIndex >= 0
                  ? String.fromCharCode(65 + correctAnswerIndex)
                  : null;
              final wasCorrect =
                  myChoiceLetter != null &&
                  myChoiceLetter == correctAnswerLetter;

              if (myChoiceLetter == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 12),
                      Text(
                        'لم يتم إرسال إجابة في الوقت المحدد!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ).animate().shake();
              } else if (wasCorrect) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Text(
                        ' إجابة صحيحة (+1 نقطة)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms);
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '❌ إجابة خاطئة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ).animate().shake();
              }
            },
          ),
          const SizedBox(height: 24),
        ],

        // Options: Appear in Step 1, all stay visible
        if (step >= 1)
          AnimatedSize(
            duration: 800.ms,
            curve: Curves.easeInOutBack,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(question.options.length, (index) {
                final optionText = question.options[index];
                final letter = String.fromCharCode(65 + index);
                final isCorrect = optionText == question.correctAnswer;
                final isWrong = step >= 3 && !isCorrect;
                final isSelectedByMe = _selectedOption == letter;

                final votingTeams = (gameProvider.hideVotes || step < 2)
                    ? <String>[]
                    : gameProvider.realtimeChoices.entries
                          .map(
                            (e) => MapEntry(
                              e.key,
                              _getDisplayedChoice(e.key, gameProvider),
                            ),
                          )
                          .where((e) => e.value == letter)
                          .map((e) => e.key)
                          .toList();

                return SizedBox(
                  width: isWide ? 450 : double.infinity,
                  child:
                      _buildOptionCard(
                            theme: theme,
                            letter: letter,
                            text: optionText,
                            isSelected: isSelectedByMe,
                            isCorrect: step >= 3 && isCorrect,
                            isWrong: isWrong,
                            teamColor: teamColor,
                            votingTeams: votingTeams,
                            gameProvider: gameProvider,
                            index: index,
                          )
                          .animate(target: step >= 1 ? 1 : 0)
                          .slideY(begin: 0.2, end: 0, delay: (100 * index).ms)
                          .fadeIn(delay: (100 * index).ms),
                );
              }),
            ),
          ),

        // Explanation: Fades in below the correct answer in Step 4
        if (step >= 4)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildExplanationCard(
              theme,
              question.explanation,
              correctAnswer: question.correctAnswer,
              isWide: isWide,
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
          ),
      ],
    );
  }

  // _buildCorrectAnswerOnly is no longer needed since we use _buildOptionCard directly

  Widget _buildFullPageLeaderboard(ThemeData theme, GameProvider gameProvider) {
    final isDark = theme.brightness == Brightness.dark;
    final teams = gameProvider.teams.values
        .where((t) => t['is_registered'] == true)
        .toList();
    teams.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Container(
      color: isDark ? AppColor.backgroundColor : theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 70, color: Colors.amber)
              .animate()
              .scale(duration: 800.ms, curve: Curves.elasticOut)
              .shimmer(duration: 2.seconds),
          const SizedBox(height: 12),
          Text(
            'لوحة الترتيب المباشرة',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الترتيب الحالي للفرق المنافسة في هذه المرحلة',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final color = Color(
                      int.parse(team['color']?.toString() ?? '0xFFFFFFFF'),
                    );
                    final iconCode =
                        team['icon_code'] as int? ?? Icons.groups.codePoint;

                    return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? color.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: isDark ? 0.25 : 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Icon(
                                IconHelper.getIconFromCode(iconCode, fallback: Icons.groups),
                                color: color,
                                size: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  team['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${team['score'] ?? 0} ن',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideX(begin: 0.2, end: 0, delay: (80 * index).ms)
                        .fadeIn(delay: (80 * index).ms);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    GameProvider gameProvider,
    Color teamColor,
  ) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.gameInfoStream,
      builder: (context, snapshot) {
        final step = gameProvider.questionStep;
        final gameData = snapshot.data ?? {};
        final stages = gameData['stages'] as List? ?? [];
        final currentStageIdx = (gameData['current_stage_index'] ?? 0) as int;
        String stageName = 'جاري التحميل...';

        if (stages.isNotEmpty && currentStageIdx < stages.length) {
          stageName = stages[currentStageIdx]['name'] ?? 'مرحلة مجهولة';
        }

        final chronoData = Map<String, dynamic>.from(
          gameData['chrono'] as Map? ?? {},
        );
        final chronoStatus = chronoData['status'] ?? 'stopped';
        final remaining = _computeRemainingSeconds(chronoData);

        final myTeamName = gameProvider.currentTeam?.name;
        int myScore = 0;
        if (myTeamName != null) {
          final teamEntry = gameProvider.teams.values.firstWhere(
            (t) => t['name'] == myTeamName,
            orElse: () => null,
          );
          if (teamEntry != null) {
            myScore = teamEntry['score'] ?? 0;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageName.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      gameProvider.isSpectator
                          ? 'وضع المشاهدة الحية'
                          : 'وضع التحدي المباشر',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white38
                            : Colors.black54,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  if (chronoStatus != 'stopped' && step == 1)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chronoStatus == 'paused'
                            ? Colors.amber.withValues(alpha: 0.15)
                            : (remaining <= 10
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : (theme.brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05))),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: chronoStatus == 'paused'
                              ? Colors.amber
                              : (remaining <= 10
                                  ? Colors.redAccent
                                  : AppColor.primaryColor.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chronoStatus == 'paused' ? Icons.pause_circle : Icons.timer,
                            color: chronoStatus == 'paused'
                                ? Colors.amber
                                : (remaining <= 10
                                    ? Colors.redAccent
                                    : AppColor.primaryColor),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chronoStatus == 'paused'
                                ? '$remaining ث (موقوف)'
                                : '$remaining ث',
                            style: TextStyle(
                              color: chronoStatus == 'paused'
                                  ? Colors.amber
                                  : (remaining <= 10
                                      ? Colors.redAccent
                                      : (theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87)),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [teamColor, teamColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: teamColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      gameProvider.isSpectator
                          ? 'السؤال ${gameProvider.currentQuestionIndex + 1}'
                          : 'السؤال ${gameProvider.currentQuestionIndex + 1} | $myScore ن',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionSection(
    ThemeData theme,
    dynamic question, {
    bool isWide = false,
    bool isCentered = false,
    bool isMini = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final questionWidget = Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
      padding: EdgeInsets.all(isWide ? 60 : 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Text(
        question.questionText,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w900,
          height: 1.4,
          fontSize: isWide ? 44 : 24,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );

    return AnimatedScale(
      scale: isMini ? 0.65 : 1.0,
      duration: 800.ms,
      curve: Curves.easeInOutQuad,
      alignment: Alignment.topCenter,
      child: questionWidget
          .animate(key: ValueKey(question.questionText))
          .fadeIn(duration: 600.ms)
          .scale(
            duration: 600.ms,
            begin: const Offset(0.95, 0.95),
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required String letter,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required Color teamColor,
    required List<String> votingTeams,
    required GameProvider gameProvider,
    required int index,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    // Determine colors based on state
    Color bgColor;
    Color borderColor;
    double borderWidth;
    Color circleColor;
    Color textColor;

    if (isCorrect) {
      bgColor = AppColor.correctColor.withValues(alpha: isDark ? 0.2 : 0.15);
      borderColor = AppColor.correctColor;
      borderWidth = 2.5;
      circleColor = AppColor.correctColor;
      textColor = AppColor.correctColor;
    } else if (isWrong) {
      bgColor = Colors.redAccent.withValues(alpha: 0.08);
      borderColor = Colors.redAccent.withValues(alpha: 0.4);
      borderWidth = 1.5;
      circleColor = Colors.redAccent.withValues(alpha: 0.3);
      textColor = isDark ? Colors.white38 : Colors.black38;
    } else if (isSelected) {
      bgColor = teamColor.withValues(alpha: 0.15);
      borderColor = teamColor;
      borderWidth = 2.5;
      circleColor = teamColor;
      textColor = teamColor;
    } else {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1);
      borderWidth = 1;
      circleColor = isDark
          ? Colors.white10
          : Colors.black.withValues(alpha: 0.06);
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectOption(letter),
        child: AnimatedContainer(
          duration: 400.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (isSelected || isCorrect)
                BoxShadow(
                  color: (isCorrect ? AppColor.correctColor : teamColor)
                      .withValues(alpha: 0.15),
                  blurRadius: 15,
                )
              else if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isWrong
                      ? const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        )
                      : isCorrect
                      ? const Icon(Icons.check, color: Colors.black, size: 18)
                      : Text(
                          letter,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: isSelected || isCorrect
                        ? FontWeight.w900
                        : FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                    decoration: isWrong ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (votingTeams.isNotEmpty)
                _buildVotingStack(votingTeams, gameProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingStack(
    List<String> votingTeams,
    GameProvider gameProvider,
  ) {
    return Row(
      children: votingTeams.map((teamName) {
        final teamData = gameProvider.teams.values.firstWhere(
          (t) => t['name'] == teamName,
          orElse: () => {},
        );
        final color = Color(
          int.parse(teamData['color']?.toString() ?? '0xFFFFFFFF'),
        );
        final iconCode =
            teamData['icon_code'] as int? ?? Icons.person.codePoint;
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            IconHelper.getIconFromCode(iconCode, fallback: Icons.groups),
            size: 14,
            color: color,
          ),
        ).animate().scale().fadeIn();
      }).toList(),
    );
  }

  Widget _buildExplanationCard(
    ThemeData theme,
    String explanation, {
    String? correctAnswer,
    bool isWide = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
      decoration: BoxDecoration(
        color: isDark
            ? AppColor.primaryColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColor.primaryColor.withValues(alpha: 0.2)
              : AppColor.primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (correctAnswer != null && correctAnswer.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.correctColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.correctColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColor.correctColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'الإجابة الصحيحة: ',
                    style: TextStyle(
                      color: AppColor.correctColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      correctAnswer,
                      style: const TextStyle(
                        color: AppColor.correctColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColor.primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                'معلومات إضافية وشرح',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColor.primaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: TextStyle(
              height: 1.6,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLogosPhase(ThemeData theme, bool isWide) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'برعاية وتنظيم',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 60),
        Wrap(
          spacing: 60,
          runSpacing: 60,
          alignment: WrapAlignment.center,
          children: [
            _buildLogoItem(
              'assets/images/aliqama_logo.png',
              'الإقامة الجامعية',
              0,
              isWide,
              isCircular: true,
              isDark: isDark,
            ),
            _buildLogoItem(
              'assets/images/club_logo.png',
              'نادي رفعة',
              1,
              isWide,
              isCircular: true,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoItem(
    String path,
    String label,
    int index,
    bool isWide, {
    bool isCircular = false,
    bool isDark = true,
  }) {
    final size = isWide ? 180.0 : 120.0;
    return Column(
      children: [
        Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.antiAlias,
              child: ClipOval(child: Image.asset(path, fit: BoxFit.contain)),
            )
            .animate(delay: (200 * index).ms)
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn(),
        const SizedBox(height: 20),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ).animate(delay: (200 * index + 300).ms).fadeIn(),
      ],
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

  bool _isTeamFrozen(String teamId, GameProvider gameProvider) {
    return gameProvider.activeTraps.values.any(
      (t) => t['type'] == 'freeze' && t['target'] == teamId,
    );
  }

  String? _getDisplayedChoice(String teamId, GameProvider gameProvider) {
    final realChoice = gameProvider.realtimeChoices[teamId];
    if (realChoice == null) return null;

    final scrambleTrap = gameProvider.activeTraps.values.firstWhere(
      (t) => t['type'] == 'scramble' && t['by'] == teamId,
      orElse: () => null,
    );

    if (scrambleTrap != null && scrambleTrap['fake_vote'] != null) {
      return scrambleTrap['fake_vote'];
    }
    return realChoice;
  }

  Widget _buildQuestionLoading(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppColor.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل السؤال...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme, bool isWide) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColor.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            '🏆 مسابقة CUBE 3 🏆',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColor.primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 40),
        Text(
          'مرحباً بكم في المواجهة النهائية',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
              'الرجاء الاستعداد للبدء... التركيز والسرعة هما مفتاح الفوز!',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(delay: 400.ms)
            .shimmer(duration: 2.seconds),
        const SizedBox(height: 60),
        Text(
          'تنظيم ورعاية متميزة من:',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 40),
        Wrap(
          spacing: 40,
          runSpacing: 40,
          alignment: WrapAlignment.center,
          children: [
            _buildLogoItem(
              'assets/images/aliqama_logo.png',
              'الإقامة الجامعية',
              0,
              isWide,
              isCircular: true,
              isDark: isDark,
            ),
            _buildLogoItem(
              'assets/images/club_logo.png',
              'نادي رفعة',
              1,
              isWide,
              isCircular: true,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStageIntroScreen(
    ThemeData theme,
    Map<String, dynamic> gameData,
    bool isWide,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final stages = gameData['stages'] as List? ?? [];
    final currentStageIdx = (gameData['current_stage_index'] ?? 0) as int;
    String stageName = 'المرحلة القادمة';

    if (stages.isNotEmpty && currentStageIdx < stages.length) {
      final stage = stages[currentStageIdx];
      stageName = stage['name'] ?? 'مرحلة جديدة';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.stars, size: 80, color: AppColor.primaryColor)
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 3.seconds)
            .scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primaryColor.withValues(alpha: 0.15),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColor.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            stageName.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColor.primaryColor,
              shadows: [Shadow(color: AppColor.primaryColor, blurRadius: 15)],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 48),
        Text(
              'سيبدأ السؤال الأول بعد قليل... استعدوا!',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black54,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(delay: 500.ms)
            .shimmer(duration: 1.5.seconds),
      ],
    );
  }
}
