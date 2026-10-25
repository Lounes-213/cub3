import 'dart:async';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../models/question_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';

class WhoAmIStage extends StatefulWidget {
  const WhoAmIStage({super.key});

  @override
  State<WhoAmIStage> createState() => _WhoAmIStageState();
}

class _WhoAmIStageState extends State<WhoAmIStage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitted = false;
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  int? _lastQuestionIndex;
  late QuestionModel _question;

  void _startHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_currentHintIndex < 2) {
        if (mounted) setState(() => _currentHintIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startHintTimer();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() async {
    final ans = _answerController.text.trim();
    if (ans.isEmpty) return;
    final team = context.read<GameProvider>().currentTeam;
    if (team == null) return;
    setState(() => _isSubmitted = true);
    int points = _currentHintIndex == 0 ? 5 : (_currentHintIndex == 1 ? 3 : 1);
    await _firebaseService.submitAnswer(team.name, 'who_am_i', {
      'answer': ans,
      'hint_level': _currentHintIndex + 1,
      'points_potential': points,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 80, color: AppColor.primaryColor).animate().scale().shimmer(),
              const SizedBox(height: 24),
              Text('تم إرسال إجابتك!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('ننتظر تقييم الأدمن...', style: TextStyle(color: AppColor.getTextSecondary(context))),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColor.primaryColor),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<GameProvider>();
    final question = provider.currentQuestion;

    // سؤال جديد: نصفّر الإجابة واللمحات (كل سؤال يبدأ من جديد)
    if (_lastQuestionIndex != provider.currentQuestionIndex) {
      _lastQuestionIndex = provider.currentQuestionIndex;
      _isSubmitted = false;
      _currentHintIndex = 0;
      _answerController.clear();
      _startHintTimer();
    }

    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _question = question;

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('المرحلة 5: من أنا؟'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHintCard(1, _question.hint1, true, 5, isDark),
            _buildHintCard(2, _question.hint2, _currentHintIndex >= 1, 3, isDark),
            _buildHintCard(3, _question.hint3, _currentHintIndex >= 2, 1, isDark),
            const SizedBox(height: 40),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: 'من هو؟...',
                prefixIcon: const Icon(Icons.help_center),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppColor.primaryColor),
                  onPressed: _submitAnswer,
                ),
              ),
              onSubmitted: (_) => _submitAnswer(),
            ).animate().slideY(begin: 0.2, end: 0, delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard(int num, String text, bool visible, int points, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: visible
            ? (isDark ? AppColor.surfaceColor : Colors.white)
            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: visible
              ? AppColor.primaryColor.withValues(alpha: isDark ? 0.2 : 0.3)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
        boxShadow: visible && !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: visible
                ? AppColor.primaryColor
                : (isDark ? Colors.white10 : Colors.black12),
            child: Text(
              '$num',
              style: TextStyle(
                color: visible
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.black38),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visible ? text : 'يظهر قريباً...',
                  style: TextStyle(
                    fontSize: 16,
                    color: visible
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white24 : Colors.black26),
                    fontWeight: visible ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (visible) ...[
                  const SizedBox(height: 4),
                  Text('نقاط: $points', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
