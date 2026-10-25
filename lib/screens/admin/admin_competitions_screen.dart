import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firebase_service.dart';
import '../../theme/theme.dart';
import '../../widgets/glass_app_bar.dart';
import 'admin_dashboard.dart';
import 'admin_history_screen.dart';
import 'admin_questions_screen.dart';
import 'create_competition_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'admin_settings_dialog.dart';
import '../arena_screen.dart';

/// شاشة المسابقات — نقطة الدخول الوحيدة للإدارة:
/// إنشاء مسابقة / بنك الأسئلة / مركز العمليات المباشر /
/// المسابقات المحفوظة / سجل النتائج.
class AdminCompetitionsScreen extends StatefulWidget {
  const AdminCompetitionsScreen({super.key});

  @override
  State<AdminCompetitionsScreen> createState() =>
      _AdminCompetitionsScreenState();
}

class _AdminCompetitionsScreenState extends State<AdminCompetitionsScreen> {
  final FirebaseService _service = FirebaseService();
  Map<String, dynamic> _gameData = const {};

  String get _status => (_gameData['status'] as String?) ?? 'none';
  bool get _isLive => _status == 'waiting' || _status == 'playing';

  int _registeredCount(Map<String, dynamic> gameData) {
    final teams = gameData['teams'];
    if (teams is! Map) return 0;
    return teams.values
        .where((t) => t is Map && t['is_registered'] == true)
        .length;
  }

  String _stageName(Map<String, dynamic> gameData) {
    final stages = gameData['stages'];
    final idx = gameData['current_stage_index'] ?? 0;
    if (stages is List && idx < stages.length && stages[idx] is Map) {
      return (stages[idx] as Map)['name']?.toString() ?? '';
    }
    return '';
  }

  // إطلاق مسابقة محفوظة — إمكانية تسميتها وتعيين المشرف المنشئ
  Future<void> _launchFromLibrary(String name, Map<String, dynamic> cfg) async {
    final userProvider = context.read<UserProvider>();
    final myMatricule = userProvider.matricule.isNotEmpty ? userProvider.matricule : 'admin';
    final myName = userProvider.fullNameAr;

    final creatorId = _gameData['creator_id'];
    final isMyLiveComp = creatorId == null || creatorId == myMatricule || creatorId == 'admin';

    if (_isLive && !isMyLiveComp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('توجد مسابقة جارية خاصة بالمشرف «${_gameData['creator_name'] ?? creatorId}». لا يمكنك استبدالها.'),
          backgroundColor: AppColor.wrongColor,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: (cfg['title'] as String?) ?? name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: AppColor.correctColor, size: 22),
            SizedBox(width: 8),
            Text('تسمية وإطلاق المسابقة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حدد اسم هذه الدورة قبل بدء البث:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'اسم المسابقة',
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_isLive) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'تنبيه: إطلاق مسابقة جديدة سيستبدل المسابقة الجارية ويعيد ضبط قاعة الانتظار.',
                  style: TextStyle(color: Colors.amber, fontSize: 11.5),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.correctColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('إطلاق الآن', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final chosenTitle = nameController.text.trim().isNotEmpty ? nameController.text.trim() : name;
    final stages = (cfg['stages'] as List?)
        ?.map((s) => Map<String, dynamic>.from(s))
        .toList();

    await _service.updateGameState(
      status: 'waiting',
      numTeams: (cfg['num_teams'] as num?)?.toInt() ?? 4,
      teamSize: (cfg['team_size'] as num?)?.toInt() ?? 3,
      title: chosenTitle,
      date: (cfg['date'] as String?) ?? '',
      stages: stages,
      creatorId: myMatricule,
      creatorName: myName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إطلاق «$chosenTitle» — مرحباً بك في مركز العمليات')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
    );
  }

  Future<void> _deleteFromLibrary(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        title: const Text('حذف المسابقة المحفوظة',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: Text('هل تريد حذف «$name» من المكتبة؟',
            style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppColor.wrongColor))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteCompetitionFromLibrary(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('المسابقات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _service.gameInfoStream,
        builder: (context, snapshot) {
          final gameData = snapshot.data ?? const {};
          _gameData = gameData;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // زر إنشاء مسابقة جديدة البارز
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateCompetitionScreen()),
                  ),
                  icon: const Icon(Icons.add_circle, size: 24),
                  label: const Text(
                    '+ Ajouter Musabaqa (إنشاء مسابقة جديدة)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              _liveCard(gameData),
              const SizedBox(height: 22),
              _sectionLabel('الإجراءات'),
              _actionGrid(context),
              const SizedBox(height: 20),
              _sectionLabel('المسابقات المحفوظة'),
              _libraryList(),
              const SizedBox(height: 20),
              _sectionLabel('سجل النتائج'),
              _historyTile(context),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // بطاقته الحالة المباشرة
  // ----------------------------------------------------
  Widget _liveCard(Map<String, dynamic> gameData) {
    final userProvider = context.watch<UserProvider>();
    final myMatricule = userProvider.matricule.isNotEmpty ? userProvider.matricule : 'admin';
    final creatorId = gameData['creator_id'];
    final creatorName = gameData['creator_name'] ?? 'مشرف آخر';
    final isMyCompetition = creatorId == null || creatorId == myMatricule || creatorId == 'admin';

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String desc;
    late final Widget action;

    switch (_status) {
      case 'waiting':
        icon = isMyCompetition ? Icons.hourglass_top : Icons.lock_clock;
        color = AppColor.warningColor;
        title = isMyCompetition ? 'مسابقة في قاعة الانتظار' : 'مسابقة قيد الانتظار (خاصة بـ $creatorName)';
        desc = isMyCompetition
            ? 'انضم ${_registeredCount(gameData)} / ${gameData['num_teams'] ?? 0} فرق — «${gameData['title'] ?? ''}»'
            : '«${gameData['title'] ?? ''}» — مسابقة المشرف $creatorName. لا يمكنك التحكم بها.';
        action = isMyCompetition
            ? _primaryButton('مركز العمليات', Icons.dashboard_outlined,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminDashboard())))
            : _primaryButton('مشاهدة كمتفرج', Icons.visibility_outlined,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ArenaScreen())));
        break;
      case 'playing':
        icon = isMyCompetition ? Icons.play_circle_fill : Icons.lock_outline;
        color = AppColor.correctColor;
        final stage = _stageName(gameData);
        title = isMyCompetition ? 'مسابقة جارية الآن' : 'مسابقة جارية (خاصة بـ $creatorName)';
        desc = isMyCompetition
            ? '«${gameData['title'] ?? ''}»${stage.isEmpty ? '' : ' — $stage'}'
            : '«${gameData['title'] ?? ''}» — تحت إدارة $creatorName.';
        action = isMyCompetition
            ? _primaryButton('مركز العمليات', Icons.dashboard_outlined,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminDashboard())))
            : _primaryButton('مشاهدة كمتفرج', Icons.visibility_outlined,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ArenaScreen())));
        break;
      case 'finished':
        icon = Icons.emoji_events_outlined;
        color = AppColor.primaryColor;
        title = 'انتهت المسابقة';
        desc =
            '«${gameData['title'] ?? ''}» — النتائج محفوظة في سجل النتائج';
        action = _primaryButton(
            'عرض النتائج', Icons.leaderboard_outlined, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminHistoryScreen()));
        });
        break;
      default:
        icon = Icons.emoji_events_outlined;
        color = Colors.white24;
        title = 'لا توجد مسابقة جارية';
        desc = 'أنشئ مسابقة جديدة أو شغّل واحدة من المسابقات المحفوظة';
        action = _primaryButton('إنشاء مسابقة', Icons.add, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateCompetitionScreen()));
        });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          action,
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _primaryButton(
      String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 13),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // الإجراءات: إنشاء مسابقة + بنك الأسئلة
  // ----------------------------------------------------
  Widget _actionGrid(BuildContext context) {
    final actions = <_Action>[
      _Action(
        'بنك الأسئلة',
        'إضافة وتعديل وحذف الأسئلة',
        Icons.quiz_outlined,
        const Color(0xFF0EA5E9),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminQuestionsScreen())),
      ),
      _Action(
        'إعدادات المسابقة',
        'ضبط العنوان، الفرق والخيارات',
        Icons.settings_outlined,
        const Color(0xFF8B5CF6),
        () => showDialog(
          context: context,
          builder: (_) => AdminSettingsDialog(gameData: _gameData),
        ),
      ),
      _Action(
        'واجهة المواجهات',
        'عرض مباشر لشاشة اللعبة',
        Icons.visibility_outlined,
        const Color(0xFF10B981),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArenaScreen()),
        ),
      ),
      _Action(
        'إنشاء مسابقة جديدة',
        'اسم، عدد الفرق، المراحل والأسئلة',
        Icons.add_circle_outline,
        const Color(0xFFF97316),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateCompetitionScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (var i = 0; i < actions.length; i++)
          _actionTile(actions[i], i),
      ],
    );
  }

  Widget _actionTile(_Action a, int index) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: a.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 20),
            ),
            const Spacer(),
            Text(a.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(a.desc,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06),
    );
  }

  // ----------------------------------------------------
  // المسابقات المحفوظة (المكتبة)
  // ----------------------------------------------------
  Widget _libraryList() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _service.competitionsLibraryStream,
      builder: (context, snapshot) {
        final library = snapshot.data ?? const {};
        if (library.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('لا توجد مسابقات محفوظة بعد',
                  style: TextStyle(color: Colors.white38, fontSize: 12.5)),
            ),
          );
        }

        final entries = library.entries.toList()
          ..sort((a, b) => (b.value['created_at'] ?? '')
              .toString()
              .compareTo((a.value['created_at'] ?? '').toString()));

        final userProvider = context.watch<UserProvider>();
        final myId = userProvider.matricule;

        return Column(
          children: [
            for (final e in entries)
              Builder(
                builder: (context) {
                  final creatorId = e.value['creator_id'] as String?;
                  final creatorName = e.value['creator_name'] as String?;
                  final isMine = creatorId == null || creatorId.isEmpty || creatorId == myId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: AppColor.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_circle_outline,
                        color: AppColor.primaryColor, size: 22),
                  ),
                  title: Text(e.key,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${(e.value['stages'] as List?)?.length ?? 0} مراحل • '
                    '${e.value['num_teams'] ?? 0} فرق'
                    '${creatorName != null && creatorName.isNotEmpty ? ' • المشرف: $creatorName' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow,
                            color: AppColor.correctColor, size: 22),
                        tooltip: 'إطلاق',
                        onPressed: () => _launchFromLibrary(
                            e.key, Map<String, dynamic>.from(e.value)),
                      ),
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColor.primaryColor, size: 19),
                          tooltip: 'تعديل',
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateCompetitionScreen(
                                  existingData:
                                      Map<String, dynamic>.from(e.value),
                                  existingKey: e.key,
                                ),
                              )),
                        ),
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColor.wrongColor, size: 19),
                          tooltip: 'حذف',
                          onPressed: () => _deleteFromLibrary(e.key),
                        ),
                    ],
                  ),
                ),
              ),
              );
            },
          ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // سجل النتائج
  // ----------------------------------------------------
  Widget _historyTile(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminHistoryScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.leaderboard_outlined,
                color: AppColor.primaryColor, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سجل النتائج',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5)),
                  SizedBox(height: 3),
                  Text('المسابقات المنتهية، الترتيب النهائي وحذف السجلات',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: Colors.white38),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppColor.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07)),
          ),
        ],
      ),
    );
  }
}

class _Action {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _Action(this.title, this.desc, this.icon, this.color, this.onTap);
}
