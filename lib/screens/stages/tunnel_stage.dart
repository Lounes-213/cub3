import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../models/question_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';

class TunnelStage extends StatefulWidget {
  const TunnelStage({super.key});

  @override
  State<TunnelStage> createState() => _TunnelStageState();
}

class _TunnelStageState extends State<TunnelStage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitted = false;
  late List<QuestionModel> _tunnelQuestions;
  final Map<int, String> _selectedAnswers = {};
  int? _lastStageIndex;

  @override
  void initState() {
    super.initState();
  }

  void _submitAllAnswers() async {
    if (_selectedAnswers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء الإجابة على جميع الأسئلة.')),
      );
      return;
    }

    final team = context.read<GameProvider>().currentTeam;
    if (team == null) return;

    setState(() => _isSubmitted = true);

    await _firebaseService.submitAnswer(
      team.name,
      'tunnel',
      {
        'answers': _selectedAnswers.map((key, value) => MapEntry('q_$key', value)),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GameProvider>();
    _tunnelQuestions = provider.questions.take(5).toList();

    // مرحلة جديدة = نفق جديد (نمسح الإجابات المحفوظة)
    if (_lastStageIndex != provider.currentStageIndex) {
      _lastStageIndex = provider.currentStageIndex;
      _isSubmitted = false;
      _selectedAnswers.clear();
    }

    if (_tunnelQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dark_mode, size: 80, color: AppColor.secondaryColor).animate().scale().shimmer(),
              const SizedBox(height: 24),
              Text('خرجت من النفق بسلام!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('ننتظر خروج بقية الفرق لمعرفة النتائج.', style: TextStyle(color: AppColor.getTextSecondary(context))),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColor.secondaryColor),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('المرحلة 3: النفق'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: isDark ? AppColor.surfaceColor : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.speed, color: AppColor.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'تقدمك: ${_selectedAnswers.length} من 5',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _tunnelQuestions.length,
              itemBuilder: (context, index) => _buildQuestionCard(_tunnelQuestions[index], index, isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _selectedAnswers.length == 5 ? _submitAllAnswers : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAnswers.length == 5
                    ? AppColor.primaryColor
                    : (isDark ? Colors.white10 : Colors.black12),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: Text(
                'إرسال النتائج السرية',
                style: TextStyle(
                  color: _selectedAnswers.length == 5
                      ? Colors.white
                      : (isDark ? Colors.white24 : Colors.black26),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int qIndex, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColor.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('سؤال ${qIndex + 1}', style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...question.options.map((option) {
            final isSel = _selectedAnswers[qIndex] == option;
            return GestureDetector(
              onTap: () => setState(() => _selectedAnswers[qIndex] = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColor.primaryColor.withValues(alpha: 0.15)
                      : (isDark ? AppColor.backgroundColor : const Color(0xFFF1F5F2)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel
                        ? AppColor.primaryColor
                        : (isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05)),
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.check_circle : Icons.circle_outlined,
                      color: isSel ? AppColor.primaryColor : (isDark ? Colors.white24 : Colors.black26),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSel
                              ? AppColor.primaryColor
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 100 * qIndex));
  }
}
