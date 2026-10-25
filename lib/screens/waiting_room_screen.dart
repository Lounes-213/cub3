import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/game_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/preference_service.dart';
import '../../theme/theme.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gameProvider = context.watch<GameProvider>();
    final isSpectator = gameProvider.isSpectator;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isSpectator, isDark),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: FirebaseService().teamsStream,
                builder: (context, snapshot) {
                  final teams = (snapshot.data ?? {}).values.where((t) => t['is_registered'] == true).toList();
                  
                  if (teams.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_add_outlined, size: 80, color: isDark ? Colors.white10 : Colors.black12),
                          const SizedBox(height: 24),
                          Text(
                            'في انتظار انضمام الفرق...',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black45,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final color = Color(int.parse(team['color']?.toString() ?? '0xFFFFFFFF'));
                      final iconCode = team['icon_code'] as int? ?? Icons.person.codePoint;
                      final isMe = gameProvider.currentTeam?.name == team['name'];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? color.withValues(alpha: isDark ? 0.15 : 0.1)
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isMe ? color : (isDark ? Colors.white10 : Colors.black12),
                            width: isMe ? 2 : 1,
                          ),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(IconHelper.getIconFromCode(iconCode, fallback: Icons.groups), color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    team['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${team['members']?.length ?? 0} أعضاء',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white38 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe)
                              IconButton(
                                icon: Icon(Icons.edit, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                onPressed: () => _showEditTeamDialog(context, team),
                              ),
                          ],
                        ),
                      ).animate().fadeIn().scale(delay: Duration(milliseconds: index * 50));
                    },
                  );
                },
              ),
            ),
            _buildFooter(context, theme, isSpectator, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isSpectator, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Musabaqat Cube3',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColor.primaryColor),
          ).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSpectator ? 'وضع المشاهدة - بانتظار الانطلاق' : 'مرحباً بكم في قاعة الانتظار',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isSpectator, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: AppColor.primaryColor),
          const SizedBox(height: 24),
          Text(
            'ستبدأ المنافسة فور اكتمال الفرق...',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (isSpectator) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await PreferenceService.clearAll();
                if (context.mounted) {
                  context.read<GameProvider>().resetSession();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم الخروج من وضع المشاهدة! 🚪')),
                  );
                }
              },
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('الخروج من وضع المشاهدة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final provider = context.read<GameProvider>();
                
                final reg = await PreferenceService.getTeamRegistration();
                if (reg != null) {
                  final slot = reg['slot'];
                  // Free the team slot in Firebase
                  await FirebaseService().removeTeam('team_$slot');
                }

                await PreferenceService.clearAll();
                if (context.mounted) {
                  provider.resetSession();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم إلغاء التسجيل والخروج بنجاح! 🚪')),
                  );
                }
              },
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('إلغاء التسجيل والخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, Map<dynamic, dynamic> team) {
    // Logic to edit team color/icon
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم توفير ميزة التعديل في التحديث القادم')));
  }
}
