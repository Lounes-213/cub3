import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/theme.dart';
import '../../services/preference_service.dart';
import '../../services/firebase_service.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await PreferenceService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _firebaseService.gameInfoStream,
          builder: (context, gameSnapshot) {
            final gameData = gameSnapshot.data ?? {};
            final bool isRevealed = gameData['reveal_winner'] == true;

            return StreamBuilder<Map<String, dynamic>>(
              stream: _firebaseService.teamsStream,
              builder: (context, teamsSnapshot) {
                final teamsMap = teamsSnapshot.data ?? {};
                final registeredTeams = teamsMap.entries
                    .where((e) => e.value['is_registered'] == true)
                    .map((e) => e.value)
                    .toList();
                
                // Sort teams by score descending
                registeredTeams.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(isRevealed),
                        const SizedBox(height: 40),
                        
                        // النتائج النهائية تبان للجميع (الجمهور واللاعبين)
                        // فور انتهاء المسابقة — الكشف عن البطل يضيف فقط شاشة الاحتفال
                        if (registeredTeams.isNotEmpty)
                          _buildPodium(registeredTeams),

                        if (!isRevealed && _isAdmin) ...[
                          const SizedBox(height: 28),
                          _buildAdminRevealButton(),
                        ],

                        const SizedBox(height: 60),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isRevealed) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 75, height: 75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(4),
                clipBehavior: Clip.antiAlias,
                child: ClipOval(child: Image.asset('assets/images/aliqama_logo.png', fit: BoxFit.contain)),
              ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.2),
              const SizedBox(width: 32),
              Container(
                width: 75, height: 75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(4),
                clipBehavior: Clip.antiAlias,
                child: ClipOval(child: Image.asset('assets/images/club_logo.png', fit: BoxFit.contain)),
              ).animate().fadeIn(duration: 800.ms).slideX(begin: 0.2),
            ],
          ),
          const SizedBox(height: 32),
          
          if (isRevealed)
            const Icon(Icons.emoji_events, size: 90, color: Colors.amber)
                .animate()
                .scale(duration: 1.2.seconds, curve: Curves.elasticOut)
                .shimmer(duration: 2.seconds)
          else
            const Icon(Icons.leaderboard, size: 70, color: Colors.white38)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1.seconds),
          
          const SizedBox(height: 20),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isRevealed ? [AppColor.primaryColor, Colors.amber] : [Colors.white, Colors.white60],
            ).createShader(bounds),
            child: Text(
              isRevealed ? 'بطل المسابقة!' : 'النتائج النهائية',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 10),
          
          Text(
            isRevealed ? 'تهانينا للفريق الفائز' : 'الترتيب النهائي لكل الفرق',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildPodium(List<dynamic> teams) {
    if (teams.isEmpty) return const SizedBox.shrink();
    
    final winner = teams[0];
    final color = Color(int.parse(winner['color']?.toString() ?? '0xFFFFFFFF'));

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                IconHelper.getIconFromCode(winner['icon_code'] as int?, fallback: Icons.groups),
                size: 80,
                color: color,
              ).animate().scale(delay: 500.ms, duration: 800.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                winner['name'] ?? 'فريق غير معروف',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${winner['score'] ?? 0} نقطة',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ).animate().fadeIn(delay: 1100.ms).scale(),
            ],
          ),
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
        
        // Show 2nd and 3rd places if they exist
        if (teams.length > 1) ...[
          const SizedBox(height: 40),
          const Text('باقي المراكز', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                for (int i = 1; i < teams.length && i < 3; i++)
                  _buildRunnerUp(teams[i], i + 1),
              ],
            ),
          ).animate().fadeIn(delay: 2.seconds),
        ],
      ],
    );
  }

  Widget _buildRunnerUp(dynamic team, int rank) {
    final color = Color(int.parse(team['color']?.toString() ?? '0xFFFFFFFF'));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white38),
          ),
          const SizedBox(width: 16),
          Icon(
            IconHelper.getIconFromCode(team['icon_code'] as int?, fallback: Icons.groups),
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              team['name'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Text(
            '${team['score'] ?? 0}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminRevealButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () {
          _firebaseService.revealWinner();
        },
        icon: const Icon(Icons.visibility, size: 28),
        label: const Text(
          'كشف الفائز الآن!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton.icon(
          onPressed: () async {
            await PreferenceService.clearAll();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          icon: const Icon(Icons.home),
          label: const Text('العودة للرئيسية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white24.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
