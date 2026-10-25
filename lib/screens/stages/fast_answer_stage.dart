import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';

class FastAnswerStage extends StatefulWidget {
  const FastAnswerStage({super.key});

  @override
  State<FastAnswerStage> createState() => _FastAnswerStageState();
}

class _FastAnswerStageState extends State<FastAnswerStage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitted = false;
  int? _lastQuestionIndex;

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

  void _submitAnswer(String option, bool isSpectator) async {
    if (_isSubmitted || isSpectator) return;

    final provider = context.read<GameProvider>();
    final team = provider.currentTeam;
    if (team == null) return;

    // Prevent submitting after chrono ends!
    final remaining = _computeRemainingSeconds(provider.chrono);
    if (remaining <= 0) return;

    setState(() {
      _isSubmitted = true;
    });

    // نسجل الاختيار في الحالة المباشرة حتى يحسبه الأدمين تلقائياً
    // (نفس قناة الاختيارات المستعملة في واجهة المواجهة)
    await _firebaseService.setTeamChoice(team.name, option);

    await _firebaseService.submitAnswer(
      team.name,
      'fast_answer',
      {
        'answer': option,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameProvider = context.watch<GameProvider>();
    final isSpectator = gameProvider.isSpectator;

    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.gameInfoStream,
      builder: (context, gameSnapshot) {
        final gameData = gameSnapshot.data ?? {};
        final step = gameData['question_step'] ?? 0;
        
        final question = gameProvider.currentQuestion;

        // سؤال جديد = بداية جديدة (ما يبقاش شاشة "تم الإرسال" من السؤال السابق)
        if (_lastQuestionIndex != gameProvider.currentQuestionIndex) {
          _lastQuestionIndex = gameProvider.currentQuestionIndex;
          _isSubmitted = false;
        }

        if (question == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_isSubmitted && step < 3) {
          return _buildSubmittedView(theme);
        }

        return Scaffold(
          appBar: GlassAppBar(
            title: Text(isSpectator ? 'شاشة العرض المباشرة' : 'المرحلة 1: السرعة'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            actions: [
              if (isSpectator)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.live_tv, color: AppColor.secondaryColor),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. Question Card (Always visible)
                _buildQuestionCard(theme, question.questionText, isSpectator),
                
                const SizedBox(height: 32),

                // 2. Options (Visible if step >= 1)
                if (step >= 1)
                  ...List.generate(question.options.length, (index) {
                    final letter = String.fromCharCode(65 + index);
                    final optionText = question.options[index];
                    final isCorrect = optionText == question.correctAnswer;
                    final showCorrect = step >= 3;
                    
                    return _buildOptionTile(
                      letter: letter,
                      text: optionText,
                      isSpectator: isSpectator,
                      showResults: showCorrect,
                      isCorrect: isCorrect,
                      onTap: () => _submitAnswer(letter, isSpectator),
                    );
                  }).toList().animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0)
                else if (isSpectator)
                  _buildWaitingPart('في انتظار عرض الخيارات...'),

                const SizedBox(height: 32),

                // 3. Description (Visible if step >= 4)
                if (step >= 4)
                  _buildDescriptionCard(question.explanation)
                else if (isSpectator && step >= 3)
                  _buildWaitingPart('في انتظار عرض التفسير...'),

                const SizedBox(height: 40),

                // Live Activity
                _buildLiveActivitySection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(ThemeData theme, String text, bool isLarge) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 48 : 32),
      decoration: BoxDecoration(
        color: isDark ? AppColor.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? AppColor.primaryColor.withValues(alpha: 0.3)
              : AppColor.primaryColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColor.primaryColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.bolt, size: 60, color: Colors.orangeAccent).animate(onPlay: (c) => c.repeat()).shake(hz: 2),
          const SizedBox(height: 24),
          Text(
            text,
            style: theme.textTheme.headlineMedium?.copyWith(
              height: 1.4, 
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 32 : 22,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildOptionTile({
    required String letter,
    required String text,
    required bool isSpectator,
    required bool showResults,
    required bool isCorrect,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.08);
    Color bgColor = isDark ? AppColor.surfaceColor : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    
    if (showResults) {
      if (isCorrect) {
        borderColor = AppColor.correctColor;
        bgColor = AppColor.correctColor.withValues(alpha: isDark ? 0.15 : 0.12);
        textColor = isDark ? AppColor.correctColor : const Color(0xFF007E33);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: isSpectator || showResults ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: isSpectator ? 24 : 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: showResults && isCorrect ? 3 : 1),
            boxShadow: [
              if (!isDark)
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isCorrect && showResults
                    ? AppColor.correctColor
                    : (isDark ? AppColor.backgroundColor : Colors.black.withValues(alpha: 0.06)),
                child: Text(letter, style: TextStyle(
                  fontSize: 20,
                  color: isCorrect && showResults ? Colors.white : AppColor.primaryColor, 
                  fontWeight: FontWeight.bold
                )),
              ),
              const SizedBox(width: 24),
              Expanded(child: Text(text, style: TextStyle(fontSize: isSpectator ? 22 : 18, fontWeight: isSpectator ? FontWeight.w500 : FontWeight.normal, color: textColor))),
              if (showResults && isCorrect)
                const Icon(Icons.check_circle, color: AppColor.correctColor, size: 30)
              else if (!isSpectator && !showResults)
                Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColor.primaryColor, size: 20),
              SizedBox(width: 10),
              Text('توضيح إضافي:', style: TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 16, height: 1.6, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildWaitingPart(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColor.textSecondary : Colors.black54),
          ),
          const SizedBox(width: 16),
          Text(text, style: TextStyle(color: isDark ? AppColor.textSecondary : Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLiveActivitySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.teamsStream,
      builder: (context, snapshot) {
        final teams = snapshot.data ?? {};
        final registeredTeams = teams.values.where((t) => t['is_registered'] == true).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حالة الفرق المباشرة:', style: TextStyle(fontSize: 12, color: isDark ? AppColor.textSecondary : Colors.black54)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: registeredTeams.map((team) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(team['name'] ?? '', style: TextStyle(fontSize: 10, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 8, color: AppColor.primaryColor).animate(onPlay: (c) => c.repeat()).fadeIn(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmittedView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: AppColor.correctColor).animate().scale().shimmer(),
            const SizedBox(height: 24),
            Text('تم إرسال إجابتك!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('المتفرجون والفرق الأخرى يتابعون النتائج الآن...', textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColor.textSecondary : Colors.black54)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
