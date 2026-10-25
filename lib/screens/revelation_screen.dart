import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';

class RevelationScreen extends StatelessWidget {
  const RevelationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gameProvider = context.watch<GameProvider>();
    final teamColor = gameProvider.currentTeam?.teamColor ?? theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cinematic Checkmark Reveal
              SizedBox(
                height: 250,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkles
                      ...List.generate(5, (index) {
                        return Positioned(
                          left: index.isEven ? 50.0 + (index * 20) : null,
                          right: index.isOdd ? 50.0 + (index * 20) : null,
                          top: 40.0 + (index * 30),
                          child: Icon(Icons.star, color: index.isEven ? theme.colorScheme.secondary : teamColor, size: 24)
                              .animate(onPlay: (controller) => controller.repeat())
                              .fadeIn(duration: 500.ms, delay: Duration(milliseconds: index * 200))
                              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5))
                              .fadeOut(delay: 1000.ms),
                        );
                      }),
                      // Main Checkmark Circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.check, size: 60, color: Colors.white),
                      ).animate()
                        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 800.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1000.ms, color: Colors.white54),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'الإجابة الصحيحة!',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

              Text(
                gameProvider.currentQuestion?.correctAnswer ?? '...',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: theme.colorScheme.secondary.withValues(alpha: 0.5), blurRadius: 20)],
                ),
              ).animate().fadeIn(delay: 1200.ms).scale(),

              const SizedBox(height: 40),

              // Glassmorphism Explanation Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.7 : 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    if (!isDark) const BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: teamColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(Icons.menu_book, color: teamColor),
                        ),
                        const SizedBox(width: 16),
                        Text('تفسير الإجابة', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حقائق عن الإجابة',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      gameProvider.currentQuestion?.explanation ?? '...',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1600.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // Technical Summary
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text('الملخص الفني', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  collapsedIconColor: theme.colorScheme.secondary,
                  iconColor: theme.colorScheme.secondary,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('سرعة الإجابة', '8.3 ث', Icons.bolt, theme.colorScheme.secondary, theme, isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('دقة الفريق', '80%', Icons.track_changes, teamColor, theme, isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('الترتيب', '#1', Icons.emoji_events, Colors.orange, theme, isDark),
                          ),
                        ],
                      ).animate().fadeIn(delay: 2000.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Next Question Button
              ElevatedButton(
                onPressed: () {
                  // Usually goes to next question or scoreboard
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teamColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  elevation: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back), // RTL arrow
                    const SizedBox(width: 12),
                    Text('السؤال التالي', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ).animate().fadeIn(delay: 2400.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.05)),
        boxShadow: [if (!isDark) const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
