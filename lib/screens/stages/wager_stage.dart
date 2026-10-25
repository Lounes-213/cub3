import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';

class WagerStage extends StatefulWidget {
  const WagerStage({super.key});

  @override
  State<WagerStage> createState() => _WagerStageState();
}

class _WagerStageState extends State<WagerStage> {
  final FirebaseService _firebaseService = FirebaseService();
  double _wagerPercent = 0.5;
  bool _wagerSubmitted = false;
  bool _answerSubmitted = false;
  int? _lastQuestionIndex;

  void _submitWager() => setState(() => _wagerSubmitted = true);

  void _submitAnswer(String opt) async {
    final provider = context.read<GameProvider>();
    final team = provider.currentTeam;
    if (team == null) return;
    setState(() => _answerSubmitted = true);

    // نرسل حرف الاختيار في الحالة المباشرة حتى يقدر الأدمين الحساب التلقائي
    final options = provider.currentQuestion?.options ?? const [];
    final idx = options.indexOf(opt);
    final letter = String.fromCharCode(65 + (idx < 0 ? 0 : idx));
    await _firebaseService.setTeamChoice(team.name, letter);

    await _firebaseService.submitAnswer(team.name, 'wager', {
      'wager_percentage': _wagerPercent,
      'answer': opt,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GameProvider>();

    // سؤال جديد = بداية جديدة للمراهنات والخيارات
    if (_lastQuestionIndex != provider.currentQuestionIndex) {
      _lastQuestionIndex = provider.currentQuestionIndex;
      _wagerSubmitted = false;
      _answerSubmitted = false;
      _wagerPercent = 0.5;
    }

    if (_answerSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino, size: 80, color: Colors.orangeAccent).animate().scale().shimmer(),
              const SizedBox(height: 24),
              Text('تم وضع الرهان!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('ننتظر اللحظة الحاسمة من الأدمن...', style: TextStyle(color: AppColor.getTextSecondary(context))),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.orangeAccent),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('المرحلة 6: الرهان الحاسم'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _wagerSubmitted ? _buildQuestion(theme, isDark) : _buildWagerSelection(theme, isDark),
      ),
    );
  }

  Widget _buildWagerSelection(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.trending_up, size: 80, color: AppColor.primaryColor).animate().shake(),
        const SizedBox(height: 40),
        Text('سؤال حاسم في: ${context.watch<GameProvider>().currentQuestion?.category ?? "جاري التحميل..."}', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text('حدد نسبة المخاطرة بنقاطك. الإصابة تضاعفها والخطأ يفقدها!', textAlign: TextAlign.center, style: TextStyle(color: AppColor.getTextSecondary(context))),
        const SizedBox(height: 60),
        Text('${(_wagerPercent * 100).toInt()}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColor.primaryColor)),
        Slider(
          value: _wagerPercent,
          onChanged: (v) => setState(() => _wagerPercent = v),
          activeColor: AppColor.primaryColor,
          inactiveColor: isDark ? Colors.white10 : Colors.black12,
        ),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: _submitWager,
          style: ElevatedButton.styleFrom(backgroundColor: AppColor.secondaryColor, minimumSize: const Size(double.infinity, 60)),
          child: const Text('تأكيد الرهان ورؤية السؤال'),
        ),
      ],
    );
  }

  Widget _buildQuestion(ThemeData theme, bool isDark) {
    final question = context.watch<GameProvider>().currentQuestion;
    if (question == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColor.surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColor.primaryColor.withValues(alpha: isDark ? 0.3 : 0.4)),
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
          child: Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ).animate().slideY(begin: -0.1, end: 0),
        const SizedBox(height: 40),
        ...question.options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _submitAnswer(opt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().slideX(begin: 0.1, end: 0);
        }),
      ],
    );
  }
}
