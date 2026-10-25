import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../localization/app_strings.dart';

/// خط نقل جامعي — حسب الوثيقة الرسمية «جدول توقيت الخاص بالنقل»
/// (مديرية الخدمات الجامعية الجزائر شرق / الإقامة الجامعية باب الزوار 3).
/// الأسماء تُكتب كما هي في الوثيقة (فرنسية) بدون ترجمة.
class TransportRoute {
  final String name;
  final List<String> departures;
  final List<String> returns;

  const TransportRoute({
    required this.name,
    required this.departures,
    this.returns = const [],
  });
}

const List<TransportRoute> kTransportRoutes = [
  TransportRoute(
    name: 'TAFOURAH',
    departures: [
      '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00', '15:00', '15:30',
    ],
    returns: ['17:00'],
  ),
  TransportRoute(
    name: 'BOURAOUI AMMAR',
    departures: [
      '07:50', '08:00', '09:00', '09:50', '10:30', '11:30', '12:00',
      '12:20', '13:00', '13:35', '14:40', '15:00',
    ],
    returns: ['17:30'],
  ),
  TransportRoute(
    name: 'SAIS HAMDINE',
    departures: [
      '07:30', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00',
    ],
  ),
  TransportRoute(
    name: 'ITFC',
    departures: [
      '06:45', '07:00', '07:30', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00',
    ],
    returns: ['16:00', '17:00'],
  ),
  TransportRoute(
    name: 'BOUZAREAH',
    departures: [
      '06:45', '07:00', '07:30', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00',
    ],
    returns: ['16:00', '17:00'],
  ),
  TransportRoute(
    name: 'DELY BRAHIM',
    departures: [
      '06:45', '07:00', '07:30', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00',
    ],
    returns: ['16:00', '17:00'],
  ),
];

int _minutesOf(String hhmm) {
  final p = hhmm.split(':');
  if (p.length != 2) return -1;
  final h = int.tryParse(p[0]) ?? -1;
  final m = int.tryParse(p[1]) ?? -1;
  if (h < 0 || m < 0) return -1;
  return h * 60 + m;
}

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  /// -1 = الجدول الكامل (كل الخطوط)
  int _selected = 0;

  /// أقرب رحلة بعد الآن (تُحسب وقت بناء الواجهة).
  String? _nextDeparture(List<String> departures) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    String? next;
    for (final d in departures) {
      final m = _minutesOf(d);
      if (m < 0) continue;
      if (m >= nowMin && (next == null || m < _minutesOf(next))) {
        next = d;
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          AppStrings.of(context, 'transport'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _HeaderCard(
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 20),
          _buildRouteSelector(surface, textPrimary, textSecondary),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            child: _selected < 0
                ? _buildAllRoutes(surface, textPrimary, textSecondary)
                : _buildRouteCard(
                    kTransportRoutes[_selected],
                    surface,
                    textPrimary,
                    textSecondary,
                    key: ValueKey(_selected),
                  ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColor.primaryColor.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 16, color: AppColor.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'المصدر',
                      style: TextStyle(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'جدول التوقيت الرسمي الخاص بالنقل — حافلات COUS.\n'
                  'مديرية الخدمات الجامعية الجزائر شرق، الإقامة الجامعية باب الزوار 3.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── الرأس الرسمي ──────────────────────────
  Widget _buildRouteSelector(
      Color surface, Color textPrimary, Color textSecondary) {
    final items = <(int, String)>[
      (-1, 'الجدول الكامل'),
      for (var i = 0; i < kTransportRoutes.length; i++)
        (i, kTransportRoutes[i].name),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = items[index];
          final active = _selected == value;
          return GestureDetector(
            onTap: () => setState(() => _selected = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? AppColor.primaryColor
                    : surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColor.primaryColor
                      : textSecondary.withValues(alpha: 0.2),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColor.primaryColor
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.black : textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────── بطاقة خط واحد ───────────────────────
  Widget _buildRouteCard(TransportRoute route, Color surface,
      Color textPrimary, Color textSecondary,
      {Key? key}) {
    final next = _nextDeparture(route.departures);

    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_bus,
                    color: AppColor.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'من الإقامة',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('مواعيد الانطلاق', Icons.login, textPrimary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in route.departures)
                _timeChip(d, active: d == next, textPrimary: textPrimary),
            ],
          ),
          if (route.returns.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('العودة إلى الإقامة', Icons.home_filled, textPrimary),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in route.returns)
                  _returnChip(r, textPrimary: textPrimary),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04);
  }

  // ─────────────────────── الجدول الكامل ───────────────────────
  Widget _buildAllRoutes(
      Color surface, Color textPrimary, Color textSecondary) {
    return Column(
      key: const ValueKey('all'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < kTransportRoutes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColor.primaryColor
                          .withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            size: 16, color: AppColor.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kTransportRoutes[i].name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_left,
                            size: 18,
                            color: textSecondary.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      kTransportRoutes[i].departures.join('  ·  '),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                    if (kTransportRoutes[i].returns.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'العودة: ${kTransportRoutes[i].returns.join('  ·  ')}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 320.ms);
  }

  // ────────────────────────── عناصر مساعدة ──────────────────────────
  Widget _sectionLabel(String text, IconData icon, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColor.primaryColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _timeChip(String time, {required bool active, required Color textPrimary}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? AppColor.primaryColor
            : AppColor.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColor.primaryColor
              : AppColor.primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule,
              size: 13,
              color: active ? Colors.black : AppColor.primaryColor),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              color: active ? Colors.black : textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            const Text(
              'القادم',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _returnChip(String time, {required Color textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_filled,
              size: 13, color: Colors.greenAccent),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
        border:
            Border.all(color: AppColor.primaryColor.withValues(alpha: 0.16)),
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus,
                color: AppColor.primaryColor, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'جدول توقيت النقل الجامعي',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'مديرية الخدمات الجامعية الجزائر شرق\nالإقامة الجامعية باب الزوار 3',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge('6 خطوط', Icons.route_outlined),
              const SizedBox(width: 8),
              _badge('من 06:45 إلى 17:30', Icons.schedule),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColor.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
