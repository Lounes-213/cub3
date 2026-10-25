import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';

class PointDistributionScreen extends StatefulWidget {
  const PointDistributionScreen({super.key});

  @override
  State<PointDistributionScreen> createState() =>
      _PointDistributionScreenState();
}

class _PointDistributionScreenState extends State<PointDistributionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitted = false;

  void _confirmDistribution() async {
    final gameProvider = context.read<GameProvider>();
    final team = gameProvider.currentTeam;

    if (team == null) return;

    setState(() {
      _isSubmitted = true;
    });

    await _firebaseService.submitAnswer(team.name, 'strategic_maneuver', {
      'distribution': gameProvider.distributedStars,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gameProvider = context.watch<GameProvider>();
    final teamColor =
        gameProvider.currentTeam?.teamColor ?? theme.colorScheme.primary;

    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_purple500_sharp,
                size: 80,
                color: theme.colorScheme.secondary,
              ).animate().scale().shimmer(),
              const SizedBox(height: 24),
              Text(
                'تم توزيع النجوم!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ننتظر الأدمن لكشف الإجابة الصحيحة...',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: gameProvider.remainingStars > 0
                              ? theme.colorScheme.secondary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${gameProvider.remainingStars} نجوم متاحة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: gameProvider.remainingStars > 0
                                  ? theme.colorScheme.secondary
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'السؤال 4 من 10',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '00:30',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'وزّع نجومك بذكاء',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لديك 4 نجوم — وزّعها على الإجابات التي تشك بصحتها',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
                        ),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              gameProvider.currentQuestion?.category ??
                                  'جاري التحميل...',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            gameProvider.currentQuestion?.questionText ?? '...',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Options List
                    ...(gameProvider.currentQuestion?.options ?? [])
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final optionText = entry.value;
                          final letter = String.fromCharCode(65 + index);
                          int stars =
                              gameProvider.distributedStars[letter] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: stars > 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        theme.scaffoldBackgroundColor,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  // Minus Button
                                  IconButton(
                                    onPressed: stars > 0
                                        ? () => gameProvider.removeStar(letter)
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    color: stars > 0
                                        ? Colors.redAccent
                                        : Colors.grey,
                                  ),
                                  // Stars display
                                  Row(
                                    children: List.generate(3, (index) {
                                      return Icon(
                                        index < stars
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: index < stars
                                            ? Colors.orange
                                            : Colors.grey,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  // Plus Button
                                  IconButton(
                                    onPressed:
                                        gameProvider.remainingStars > 0 &&
                                            stars < 3
                                        ? () => gameProvider.addStar(letter)
                                        : null,
                                    icon: const Icon(Icons.add_circle),
                                    color:
                                        gameProvider.remainingStars > 0 &&
                                            stars < 3
                                        ? theme.colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ).animate().slideX(
                            begin: 0.1,
                            end: 0,
                            delay: Duration(milliseconds: 100 * index),
                          );
                        }),

                    const SizedBox(height: 16),

                    // Distribution Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'توزيع أصوات الفريق',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Simple visual distribution bar
                          Builder(
                            builder: (context) {
                              int total = gameProvider.distributedStars.values
                                  .fold(0, (sum, val) => sum + val);
                              if (total == 0) return const SizedBox(height: 20);

                              double aPct =
                                  (gameProvider.distributedStars['A']! / total);
                              double bPct =
                                  (gameProvider.distributedStars['B']! / total);
                              double cPct =
                                  (gameProvider.distributedStars['C']! / total);
                              double dPct =
                                  (gameProvider.distributedStars['D']! / total);

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      if (aPct > 0)
                                        Expanded(
                                          flex: (aPct * 100).toInt(),
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: teamColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      if (bPct > 0)
                                        Expanded(
                                          flex: (bPct * 100).toInt(),
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color:
                                                  theme.colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      if (cPct > 0)
                                        Expanded(
                                          flex: (cPct * 100).toInt(),
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      if (dPct > 0)
                                        Expanded(
                                          flex: (dPct * 100).toInt(),
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (aPct > 0)
                                        Text(
                                          '${(aPct * 100).toInt()}% A',
                                          style: TextStyle(
                                            color: teamColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (bPct > 0)
                                        Text(
                                          '${(bPct * 100).toInt()}% B',
                                          style: TextStyle(
                                            color: theme.colorScheme.secondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (cPct > 0)
                                        Text(
                                          '${(cPct * 100).toInt()}% C',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (dPct > 0)
                                        Text(
                                          '${(dPct * 100).toInt()}% D',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.2, end: 0, delay: 500.ms),

                    const SizedBox(height: 32),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: gameProvider.remainingStars == 0
                          ? _confirmDistribution
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameProvider.remainingStars == 0
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (gameProvider.remainingStars == 0)
                            const Icon(Icons.check),
                          if (gameProvider.remainingStars == 0)
                            const SizedBox(width: 8),
                          Text(
                            'تأكيد التوزيع',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 600.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
