import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/auth/app_roles.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import 'admin_news_screen.dart';
import 'admin_field_program_screen.dart';
import 'user_management_screen.dart';
import 'admin_config_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_facilities_screen.dart';
import '../marketplace_screen.dart';

/// لوحة الإدارة الموحدة — بطاقات مرتّبة في ثلاث مجموعات:
/// المحتوى، الإدارة، الإعدادات.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().appRole;
    final name = context.watch<UserProvider>().fullNameAr;

    final content = <_PanelCard>[
      _PanelCard(
        'المنشورات',
        'نشر وتعديل وحذف منشورات الصفحة الرئيسية (حد أقصى 100)',
        Icons.newspaper_outlined,
        const Color(0xFF0EA5E9),
        const AdminNewsScreen(),
      ),
    ];

    final management = <_PanelCard>[
      if (role.canManageUsers)
        _PanelCard(
          'الحسابات والأدوار',
          'إنشاء الحسابات وتحديد الصلاحيات',
          Icons.manage_accounts_outlined,
          const Color(0xFF6366F1),
          const UserManagementScreen(),
        ),

      if (role.canAccessAdminPanel)
        _PanelCard(
          'برنامج الملاعب',
          'برمجة المباريات: الفريقان، الملعب والساعة كل نهار',
          Icons.sports_soccer_outlined,
          const Color(0xFF22C55E),
          const AdminFieldProgramScreen(),
        ),
      if (role.canAccessAdminPanel)
        _PanelCard(
          'الطلبات والحجوزات',
          'أوامر طبية + حجوزات الإطعام',
          Icons.receipt_long_outlined,
          const Color(0xFFF59E0B),
          const AdminOrdersScreen(),
        ),
      if (role.canAccessAdminPanel)
        _PanelCard(
          'سوق الطلبة',
          'مراجعة المعروضات وحذف المخالف منها',
          Icons.shopping_bag_outlined,
          const Color(0xFFEC4899),
          const MarketplaceScreen(),
        ),
    ];

    final settings = <_PanelCard>[
      if (role.canProgramApp)
        _PanelCard(
          'الأجنحة والمرافق',
          'صور الأجنحة وأرقام رؤساء الأجنحة',
          Icons.apartment_outlined,
          const Color(0xFF14B8A6),
          const AdminFacilitiesScreen(),
        ),
      if (role.canProgramApp)
        _PanelCard(
          'برمجة التطبيق',
          'الاسم، الخدمات، الروابط، أرقام الطوارئ',
          Icons.settings_suggest_outlined,
          const Color(0xFF8B5CF6),
          const AdminConfigScreen(),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('لوحة الإدارة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _headerCard(role, name),
          const SizedBox(height: 22),
          if (content.isNotEmpty) ...[
            _sectionLabel('المحتوى'),
            _grid(context, content),
          ],
          if (management.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('الإدارة'),
            _grid(context, management),
          ],
          if (settings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('الإعدادات'),
            _grid(context, settings),
          ],
          if (content.isEmpty && management.isEmpty && settings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('لا توجد صلاحيات إدارية لهذا الحساب',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCard(AppRole role, String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: role.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(role.icon, color: role.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'مرحباً' : 'أهلاً بك، $name',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    role.labelAr,
                    style: TextStyle(
                        color: role.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Text(
            title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<_PanelCard> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.16,
      children: [
        for (var i = 0; i < cards.length; i++)
          _panelTile(context, cards[i], i),
      ],
    );
  }

  Widget _panelTile(BuildContext context, _PanelCard c, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => c.screen)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(c.icon, color: c.color, size: 22),
                ),
                const Spacer(),
                Icon(Icons.north_east,
                    color: c.color.withValues(alpha: 0.55), size: 15),
              ],
            ),
            const Spacer(),
            Text(
              c.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              c.desc,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10.5, height: 1.35),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.06),
    );
  }
}

class _PanelCard {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final Widget screen;

  _PanelCard(this.title, this.desc, this.icon, this.color, this.screen);
}
