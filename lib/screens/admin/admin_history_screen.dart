import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../theme/theme.dart';
import '../../widgets/glass_app_bar.dart';

/// سجل النتائج — كل مسابقة تنتهي تُحفظ تلقائياً هنا.
/// الأدمين يقدر يشوف الترتيب النهائي ويحذف السجل.
class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(ApiConstants.competitionHistory);
      final history = (res is Map && res['history'] is List)
          ? res['history'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items = List<dynamic>.from(history);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل سجل النتائج. تحقق من الاتصال.';
        _loading = false;
      });
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} '
          '${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('سجل النتائج',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  color: AppColor.primaryColor,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.leaderboard_outlined,
                                size: 64, color: Colors.white12),
                            SizedBox(height: 16),
                            Center(
                              child: Text('لا توجد مسابقات منتهية بعد',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _itemTile(_items[i], i),
                        ),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.white24),
          const SizedBox(height: 14),
          Text(_error ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.primaryColor,
              side: BorderSide(
                  color: AppColor.primaryColor.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(dynamic raw, int index) {
    final item = raw is Map ? Map<String, dynamic>.from(raw) : {};
    final ranking = item['ranking'] is List ? item['ranking'] as List : const [];
    final winner = (item['winnerName'] ?? '').toString();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(id: '${item['id']}')),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppColor.primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['title'] ?? 'مسابقة'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    winner.isEmpty
                        ? _formatDate(item['finishedAt']?.toString())
                        : 'الفائز: $winner • ${_formatDate(item['finishedAt']?.toString())}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('${ranking.length} فرق',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left, color: Colors.white30, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05);
  }
}

// ----------------------------------------------------
// تفاصيل نتيجة مسابقة واحدة: البوديوم + الترتيب الكامل
// ----------------------------------------------------
class HistoryDetailScreen extends StatefulWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _item;
  bool _loading = true;
  bool _error = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await _api.get(
          '${ApiConstants.competitionHistory}/${widget.id}');
      if (!mounted) return;
      setState(() {
        _item = (res is Map && res['item'] is Map)
            ? Map<String, dynamic>.from(res['item'] as Map)
            : null;
        _loading = false;
        _error = _item == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Color _parseColor(dynamic value) {
    try {
      if (value is num) return Color(value.toInt());
      final s = value?.toString() ?? '';
      if (s.isEmpty) return AppColor.primaryColor;
      return Color(int.parse(s));
    } catch (_) {
      return AppColor.primaryColor;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} '
          '${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        title: const Text('حذف السجل',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text(
          'سيتم حذف نتائج هذه المسابقة نهائياً من السجل. هل أنت متأكد؟',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف نهائي',
                  style: TextStyle(color: AppColor.wrongColor))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _api.delete(
          '${ApiConstants.competitionHistory}/${widget.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف السجل'),
            backgroundColor: AppColor.correctColor),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر حذف السجل. حاول مرة أخرى.'),
            backgroundColor: AppColor.wrongColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('تفاصيل النتائج',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          if (!_loading && _item != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColor.wrongColor),
              tooltip: 'حذف السجل',
              onPressed: _deleting ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor))
          : (_error || _item == null)
              ? const Center(
                  child: Text('السجل غير موجود',
                      style: TextStyle(color: Colors.white38)))
              : _content(_item!),
    );
  }

  Widget _content(Map<String, dynamic> item) {
    final ranking =
        item['ranking'] is List ? item['ranking'] as List : const [];
    final top3 = ranking.take(3).toList();
    final winner = (item['winnerName'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // رأس السجل
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColor.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColor.primaryColor, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${item['title'] ?? 'مسابقة'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaChip('التاريخ', _formatDate(item['finishedAt']?.toString())),
                  _metaChip('الفرق', '${ranking.length}'),
                  _metaChip('الأسئلة المسجّلة', '${item['questionCount'] ?? 0}'),
                  if (item['status'] != null)
                    _metaChip(
                        'الحالة',
                        item['status'] == 'finished'
                            ? 'منتهية'
                            : '${item['status']}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (winner.isNotEmpty) ...[
          _sectionLabel('الفائز'),
          Container(
            padding: const EdgeInsets.all(18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.primaryColor.withValues(alpha: 0.22),
                  AppColor.primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColor.primaryColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events,
                    color: AppColor.primaryColor, size: 44),
                const SizedBox(height: 8),
                Text(winner,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('المركز الأول • ${ranking.isNotEmpty ? (ranking.first['score'] ?? 0) : 0} نقطة',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        if (top3.isNotEmpty) ...[
          _sectionLabel('البوديوم'),
          Row(
            children: [
              for (var i = 0; i < top3.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _podiumCard(top3[i], i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        if (ranking.isNotEmpty) ...[
          _sectionLabel('الترتيب الكامل'),
          Container(
            decoration: BoxDecoration(
              color: AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < ranking.length; i++)
                  _rankRow(ranking[i], i),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value',
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _podiumCard(dynamic entry, int index) {
    final team = entry is Map ? entry : const {};
    final color = _parseColor(team['color']);
    final place = index + 1;
    final medal = place == 1
        ? const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 30)
        : place == 2
            ? const Icon(Icons.emoji_events, color: Color(0xFFB0BEC5), size: 26)
            : const Icon(Icons.emoji_events, color: Color(0xFFBF8970), size: 24);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          medal,
          const SizedBox(height: 8),
          Text('${team['name'] ?? ''}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('${team['score'] ?? 0}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text('المركز $place',
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _rankRow(dynamic entry, int index) {
    final team = entry is Map ? entry : const {};
    final color = _parseColor(team['color']);
    final members = team['members'] is List
        ? (team['members'] as List).join('، ')
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: index == 0
              ? const BorderSide(color: Colors.white10)
              : BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text('${index + 1}',
                style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${team['name'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (members.isNotEmpty)
                  Text(members,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${team['score'] ?? 0}',
              style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 4),
          const Text('نقطة',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
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
