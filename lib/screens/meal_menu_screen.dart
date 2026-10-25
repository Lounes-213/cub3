import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_config_provider.dart';
import '../widgets/programmed_info_banner.dart';
import '../localization/app_strings.dart';

class DayMenu {
  final DateTime date;
  final String breakfast;
  final String lunch;
  final String dinner;

  DayMenu({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
}

class MealMenuScreen extends StatefulWidget {
  const MealMenuScreen({super.key});

  @override
  State<MealMenuScreen> createState() => _MealMenuScreenState();
}

class _MealMenuScreenState extends State<MealMenuScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<DayMenu> _allMenus = [];
  int _selectedOffset = 0; // -1 = yesterday, 0 = today, 1 = tomorrow
  DateTime? _lastFetchTime;

  static const String _menuUrl = 'https://onou.mesrs.dz/doumenu/25';

  List<Map<String, dynamic>> _dayChips(BuildContext context) => [
    {'label': AppStrings.of(context, 'yesterday'), 'offset': -1},
    {'label': AppStrings.of(context, 'today'), 'offset': 0},
    {'label': AppStrings.of(context, 'tomorrow'), 'offset': 1},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    if (_lastFetchTime == null ||
        now.difference(_lastFetchTime!).inSeconds > 3) {
      _lastFetchTime = now;
      _fetchMenu();
    }
  }

  Future<void> _fetchMenu() async {
    _lastFetchTime = DateTime.now();
    setState(() {
      _isLoading = true;
      _hasError = false;
      _allMenus = [];
    });
    try {
      final response = await http
          .get(
            Uri.parse(_menuUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'ar,fr;q=0.9,en;q=0.8',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final menus = _parseHtml(response.body);
        debugPrint('ONOU: parsed ${menus.length} days');
        for (final m in menus) {
          debugPrint(
            '  ${m.date}: B=${m.breakfast.isNotEmpty} L=${m.lunch.isNotEmpty} D=${m.dinner.isNotEmpty}',
          );
        }
        setState(() {
          _allMenus = menus;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<DayMenu> _parseHtml(String html) {
    final document = parse(html);
    final List<DayMenu> result = [];

    // Find the main table that has rows with <th scope="row"> (day headers)
    final allTables = document.getElementsByTagName('table');
    dom.Element? mainTable;
    for (final table in allTables) {
      final thRows = table.getElementsByTagName('th');
      for (final th in thRows) {
        if (th.attributes['scope'] == 'row') {
          mainTable = table;
          break;
        }
      }
      if (mainTable != null) break;
    }

    if (mainTable != null) {
      final rows = mainTable.getElementsByTagName('tr');
      for (final row in rows) {
        final th = row.querySelector('th[scope="row"]');
        if (th == null) continue;

        final dayText = _cleanText(th.text);
        final parsedDate = _tryParseDate(dayText);
        if (parsedDate == null) continue;

        final tds = row.getElementsByTagName('td');
        if (tds.length < 3) continue;

        // Each td contains a nested table with meal items
        final breakfast = _parseNestedMealTable(tds[0]);
        final lunch = _parseNestedMealTable(tds[1]);
        final dinner = _parseNestedMealTable(tds[2]);

        result.add(
          DayMenu(
            date: parsedDate,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
          ),
        );
      }
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Parses a nested meal table inside a td cell.
  /// Returns a formatted bullet list of items.
  String _parseNestedMealTable(dom.Element tdCell) {
    final nestedTables = tdCell.getElementsByTagName('table');
    if (nestedTables.isEmpty) return _cleanText(tdCell.text);

    final buffer = StringBuffer();
    for (final table in nestedTables) {
      final rows = table.getElementsByTagName('tr');
      for (final row in rows) {
        final cells = row.getElementsByTagName('td');
        if (cells.length >= 2) {
          final item = _cleanText(cells[0].text);
          final qty = _cleanText(cells[1].text);
          // Skip photo rows and empty items
          if (item.isEmpty || item.contains('صور') || item.contains('photo')) {
            continue;
          }
          if (qty.isNotEmpty) {
            buffer.writeln('• $item ($qty)');
          } else {
            buffer.writeln('• $item');
          }
        }
      }
    }
    return buffer.toString().trim();
  }

  DateTime? _tryParseDate(String text) {
    // Try ISO format: 2026-05-23
    final iso = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(text);
    if (iso != null) {
      final d = DateTime.tryParse(iso.group(1)!);
      if (d != null) return d;
    }
    // Try Algerian format: 23/05/2026
    final local = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(text);
    if (local != null) {
      final d = DateTime.tryParse(
        '${local.group(3)}-${local.group(2)}-${local.group(1)}',
      );
      if (d != null) return d;
    }
    return null;
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').replaceAll('\n', ' ').trim();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DayMenu? _getMenuForOffset(int offset) {
    final target = DateTime.now().add(Duration(days: offset));
    try {
      return _allMenus.firstWhere((m) => _isSameDay(m.date, target));
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSite() async {
    final uri = Uri.parse(_menuUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColor.backgroundColor : const Color(0xFFF5F9F6);
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final selectedMenu = _getMenuForOffset(_selectedOffset);

    return Scaffold(
      backgroundColor: bg,
      appBar: GlassAppBar(
        title: Text(
          AppStrings.of(context, 'menu_title'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        centerTitle: true,
        backgroundColor: surface,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMenu),
        ],
      ),
      body: Column(
        children: [
          ProgrammedInfoBanner.meal(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMenu,
              color: AppColor.primaryColor,
              child: _buildBody(selectedMenu, surface, textPrimary, textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    DayMenu? selectedMenu,
    Color surface,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColor.primaryColor),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context, 'load_menu_hint'),
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      // تعذر الجلب التلقائي من الموقع: نعرض برمجة الإدارة إن وُجدت،
      // وإلا لا شيء + رابط الموقع الرسمي (لا معلومات وهمية أبداً).
      final cfg = context.read<AppConfigProvider>().config;
      final hasAdminMenu = cfg.mealBreakfast.trim().isNotEmpty ||
          cfg.mealLunch.trim().isNotEmpty ||
          cfg.mealDinner.trim().isNotEmpty;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasAdminMenu) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'القائمة المبرمجة من الإدارة (تعذر الجلب التلقائي)',
                style: TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (cfg.mealBreakfast.trim().isNotEmpty)
              _buildMealCard(
                title: AppStrings.of(context, 'breakfast'),
                time: '',
                content: cfg.mealBreakfast,
                color: Colors.orangeAccent,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            if (cfg.mealLunch.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMealCard(
                title: AppStrings.of(context, 'lunch'),
                time: '',
                content: cfg.mealLunch,
                color: Colors.greenAccent,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
            if (cfg.mealDinner.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMealCard(
                title: AppStrings.of(context, 'dinner'),
                time: '',
                content: cfg.mealDinner,
                color: Colors.lightBlueAccent,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
            if (cfg.mealNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                cfg.mealNotes,
                style: TextStyle(
                    color: textSecondary, fontSize: 12, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAdminMenu ? Icons.cloud_off_outlined : Icons.wifi_off,
                    color: textSecondary.withValues(alpha: 0.4),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.of(context, 'fetch_error'),
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.of(context, 'check_internet'),
                    style: TextStyle(color: textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: _fetchMenu,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      AppStrings.of(context, 'retry'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _openSite,
                    child: Text(
                      AppStrings.of(context, 'official_site'),
                      style: const TextStyle(color: AppColor.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Day selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _dayChips(context).map((chip) {
            final isSelected = _selectedOffset == chip['offset'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(
                  chip['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.black : textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColor.primaryColor,
                backgroundColor: surface,
                side: BorderSide(
                  color: isSelected
                      ? AppColor.primaryColor
                      : textSecondary.withValues(alpha: 0.2),
                ),
                onSelected: (_) {
                  setState(() => _selectedOffset = chip['offset'] as int);
                },
              ),
            );
          }).toList(),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),

        if (selectedMenu != null) ...[
          _buildMealCard(
            title: AppStrings.of(context, 'breakfast'),
            time: '06:30 - 08:30',
            content: selectedMenu.breakfast,
            color: Colors.orangeAccent,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            title: AppStrings.of(context, 'lunch'),
            time: '11:30 - 13:30',
            content: selectedMenu.lunch,
            color: Colors.greenAccent,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            title: AppStrings.of(context, 'dinner'),
            time: '18:30 - 20:30',
            content: selectedMenu.dinner,
            color: Colors.lightBlueAccent,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  color: textSecondary.withValues(alpha: 0.4),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.of(context, 'no_menu_today'),
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.of(context, 'site_changed_hint'),
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(),

        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: _openSite,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(AppStrings.of(context, 'more_details_site')),
            style: TextButton.styleFrom(foregroundColor: AppColor.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String title,
    required String time,
    required String content,
    required Color color,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content.isNotEmpty ? content : AppStrings.of(context, 'no_data'),
              style: TextStyle(
                color: content.isNotEmpty ? textPrimary : textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
