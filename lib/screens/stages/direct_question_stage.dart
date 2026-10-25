import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';

class DirectQuestionStage extends StatefulWidget {
  const DirectQuestionStage({super.key});

  @override
  State<DirectQuestionStage> createState() => _DirectQuestionStageState();
}

class _DirectQuestionStageState extends State<DirectQuestionStage> {
  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitted = false;
  int? _lastQuestionIndex;

  void _submitAnswers() async {
    final ans1 = _answer1Controller.text.trim();
    final ans2 = _answer2Controller.text.trim();

    if (ans1.isEmpty && ans2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال إجابة واحدة على الأقل.')),
      );
      return;
    }

    final team = context.read<GameProvider>().currentTeam;
    if (team == null) return;

    setState(() => _isSubmitted = true);

    await _firebaseService.submitAnswer(
      team.name,
      'direct_question',
      {
        'answer_1': ans1,
        'answer_2': ans2,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // سؤال جديد = إجابات جديدة (ما تبقاش شاشة "تم الإرسال")
    final qIndex = context.watch<GameProvider>().currentQuestionIndex;
    if (_lastQuestionIndex != qIndex) {
      _lastQuestionIndex = qIndex;
      _isSubmitted = false;
      _answer1Controller.clear();
      _answer2Controller.clear();
    }

    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send_rounded, size: 80, color: AppColor.primaryColor).animate().scale().shimmer(),
              const SizedBox(height: 24),
              Text('تم إرسال الإجابات!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('الأدمن يقوم بتقييم إجاباتكم الآن...', style: TextStyle(color: AppColor.getTextSecondary(context))),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColor.primaryColor),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('المرحلة 4: الأسئلة المباشرة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColor.surfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: isDark ? 0.2 : 0.4)),
                boxShadow: !isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  const Icon(Icons.help_outline, size: 40, color: AppColor.primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    context.watch<GameProvider>().currentQuestion?.questionText ?? 'جاري التحميل...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: -0.1, end: 0),
            const SizedBox(height: 40),
            Text('اكتب إجابتين مختلفتين لرفع فرصة الإصابة:', style: TextStyle(color: AppColor.getTextSecondary(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: _answer1Controller,
              decoration: const InputDecoration(
                hintText: 'الإجابة الأولى...',
                prefixIcon: Icon(Icons.edit, size: 20),
              ),
            ).animate().slideX(begin: 0.1, end: 0, delay: 300.ms),
            const SizedBox(height: 16),
            TextField(
              controller: _answer2Controller,
              decoration: const InputDecoration(
                hintText: 'الإجابة الثانية (اختيارية)...',
                prefixIcon: Icon(Icons.edit_note, size: 20),
              ),
            ).animate().slideX(begin: 0.1, end: 0, delay: 500.ms),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitAnswers,
              child: const Text('إرسال الإجابات للأدمن'),
            ).animate().scale(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
