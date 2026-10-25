import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../services/preference_service.dart';
import 'onboarding_screen.dart';
import 'point_distribution_screen.dart';
import 'arena_screen.dart';
import 'waiting_room_screen.dart';
import 'game_over_screen.dart';
import 'stages/fast_answer_stage.dart';
import 'stages/tunnel_stage.dart';
import 'stages/direct_question_stage.dart';
import 'stages/who_am_i_stage.dart';
import 'stages/wager_stage.dart';

class GameRouter extends StatefulWidget {
  const GameRouter({super.key});

  @override
  State<GameRouter> createState() => _GameRouterState();
}

class _GameRouterState extends State<GameRouter> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    final role = await PreferenceService.getUserRole();
    final reg = await PreferenceService.getTeamRegistration();
    
    if (mounted) {
      final provider = context.read<GameProvider>();
      
      if (role == 'spectator') {
        provider.setSpectator(true);
      } else if (role == 'admin') {
        // Admin state is handled by the presence of the dashboard, but we ensure provider knows
      } else if (reg != null) {
        final team = Team(
          name: reg['name'],
          members: [], 
          teamColor: Color(int.parse(reg['color']?.toString() ?? '0xFFFFFFFF')),
        );
        provider.setTeam(team);
        // لا نوقف المؤقت بعد إعادة الاتصال: الزمن محسوب من السيرفر
        // (server-anchored) فاللاعب يرجع لنفس السؤال والوقت يكمل كيما هو
        // لجميع الفرق — لا يوجد تجميد جماعي بسبب انقطاع أحد.
      }
    }
  }

  String? _lastKnownStatus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.gameInfoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final gameData = snapshot.data ?? {};
        final status = gameData['status'] ?? 'idle';
        final isGameOver = gameData['is_game_over'] ?? false;
        
        final provider = context.watch<GameProvider>();

        // Detect when the competition is closed or reset — clear user session
        if (_lastKnownStatus != null && _lastKnownStatus != status) {
          if (status == 'idle' || status == 'none' || status == 'waiting') {
            // Competition was closed, reset, or a brand new one was created/opened
            Future.microtask(() async {
              await PreferenceService.clearCompetitionSession();
              if (mounted) {
                provider.resetSession();
              }
            });
          }
        }
        _lastKnownStatus = status;

        // If there's no active competition, show onboarding with a message
        if (status == 'idle' || status == 'none') {
          return const OnboardingScreen(key: ValueKey('onboarding'));
        }

        if (isGameOver) {
          return const GameOverScreen();
        }

        final isRegistered = provider.currentTeam != null || provider.isSpectator;

        // If the user hasn't registered or chosen to be a spectator, they MUST go through Onboarding!
        if (!isRegistered) {
          return const OnboardingScreen(key: ValueKey('onboarding'));
        }

        if (status == 'waiting') {
          return const WaitingRoomScreen();
        }

        final currentScreen = gameData['current_screen'] ?? 'onboarding';

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOutQuad,
          child: _getScreenWidget(currentScreen),
        );
      },
    );
  }

  Widget _getScreenWidget(String screenId) {
    switch (screenId) {
      case 'onboarding':
        return const OnboardingScreen(key: ValueKey('onboarding'));
      case 'strategic_maneuver':
        return const PointDistributionScreen(key: ValueKey('strategic_maneuver'));
      case 'leaderboard':
        return const GameOverScreen(key: ValueKey('leaderboard'));
      // كل مرحلة لها واجهتها الخاصة — تتبدل تلقائياً كي يبدلها الأدمين
      // من مركز العمليات (current_screen يتغير عبر go_to_next_stage).
      case 'fast_answer':
        return const FastAnswerStage(key: ValueKey('fast_answer'));
      case 'tunnel':
        return const TunnelStage(key: ValueKey('tunnel'));
      case 'direct_question':
        return const DirectQuestionStage(key: ValueKey('direct_question'));
      case 'who_am_i':
        return const WhoAmIStage(key: ValueKey('who_am_i'));
      case 'wager':
        return const WagerStage(key: ValueKey('wager'));
      case 'arena':
      default:
        return const ArenaScreen(key: ValueKey('arena'));
    }
  }
}
