import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../theme/theme.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';
import '../services/facility_service.dart';
import '../core/utils/image_pick.dart';
import '../core/utils/photo_utils.dart';
import '../providers/user_provider.dart';
import '../core/auth/app_roles.dart';
import '../widgets/image_viewer_dialog.dart';

class MarketplaceScreen extends StatefulWidget {
  final MarketplaceItem? initialOpenProduct;
  const MarketplaceScreen({super.key, this.initialOpenProduct});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final FacilityService _facilityService = FacilityService();

  List<MarketplaceItem> _items = [];
  bool _loading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showOnlyMyItems = false;
  int _userActiveCount = 0;
  bool _openedInitial = false;

  final List<_CategoryFilterItem> _categories = const [
    _CategoryFilterItem('all', 'الكل', Icons.all_inclusive),
    _CategoryFilterItem('books', 'كتب ومراجع', Icons.menu_book),
    _CategoryFilterItem('clothing', 'ألبسة وملابس', Icons.checkroom),
    _CategoryFilterItem('appliances', 'مستلزمات الغرف', Icons.kitchen),
    _CategoryFilterItem('electronics', 'أجهزة وإلكترونيات', Icons.devices),
    _CategoryFilterItem('free', 'مجاني / إعارة', Icons.card_giftcard),
    _CategoryFilterItem('other', 'أخرى', Icons.category),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final user = context.read<UserProvider>();
    final matricule = user.matricule;

    try {
      final items = await _marketplaceService.fetchItems();
      int userCount = 0;
      if (matricule.isNotEmpty) {
        userCount = items.where((i) => i.matricule == matricule && !i.isSold).length;
      }

      if (mounted) {
        setState(() {
          _items = items;
          _userActiveCount = userCount;
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _openedInitial) return;
          final initial = widget.initialOpenProduct;
          if (initial != null) {
            _openedInitial = true;
            final match = items.firstWhere(
                (e) => e.id.toLowerCase() == initial.id.toLowerCase(),
                orElse: () => initial);
            _openItemDetails(match);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmDeleteItem(MarketplaceItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColor.wrongColor),
            SizedBox(width: 8),
            Text('حذف هذا الغرض؟',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'سيتم حذف الغرض نهائياً مع صوره المرفوعة من التخزين السحابي.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.wrongColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _marketplaceService.deleteItem(item.id);
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ تم حذف الغرض ومسح صوره من التخزين السحابي'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تعذّر الحذف — تحقق من الاتصال وحاول مرة أخرى'),
              backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  Future<void> _toggleSoldStatus(MarketplaceItem item) async {
    final newStatus = item.isSold ? 'available' : 'sold';
    try {
      await _marketplaceService.updateItemStatus(item.id, newStatus);
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.isSold ? 'تمت إعادة عرض الغرض كمتوفر' : '✅ تهانينا! تم وسم الغرض كـ مباع'),
            backgroundColor: AppColor.correctColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تعذّرت العملية — تحقق من الاتصال وحاول مرة أخرى'),
              backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  void _openAddItemDialog() {
    final user = context.read<UserProvider>();

    // 🔐 لا يمكن نشر غرض في السوق إلا بعد تسجيل الدخول
    if (!user.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    if (_userActiveCount >= 3 && !user.appRole.canProgramApp) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColor.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColor.warningColor),
              SizedBox(width: 8),
              Text('الحد الأقصى مكتمل (3/3)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'حسب شروط الإقامة، يُسمح لكل طالب بعرض 3 أغراض كحد أقصى في وقت واحد لتكافؤ الفرص.\n\nيمكنك حذف غرض سابق أو وسمه كـ "مباع" لعرض غرض جديد.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً فهمت'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddMarketplaceItemPage(
          marketplaceService: _marketplaceService,
          facilityService: _facilityService,
          onSuccess: () {
            Navigator.pop(context);
            _loadItems();
          },
        ),
      ),
    );
  }

  void _openEditItemDialog(MarketplaceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditMarketplaceItemPage(
          item: item,
          marketplaceService: _marketplaceService,
          facilityService: _facilityService,
          onSuccess: () {
            Navigator.pop(context);
            _loadItems();
          },
        ),
      ),
    );
  }

  void _openItemDetails(MarketplaceItem item) {
    final user = context.read<UserProvider>();
    final isOwner = item.matricule == user.matricule;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductDetailScreen(
          item: item,
          isOwner: isOwner,
          isAdmin: user.appRole.canProgramApp,
          onDelete: () async {
            Navigator.pop(context);
            await _confirmDeleteItem(item);
          },
          onToggleSold: () async {
            Navigator.pop(context);
            await _toggleSoldStatus(item);
          },
          onEdit: isOwner
              ? () {
                  Navigator.pop(context);
                  _openEditItemDialog(item);
                }
              : null,
        ),
      ),
    );
  }

  /// حوار يطلب من المستخدم تسجيل الدخول قبل نشر غرض في السوق،
  /// وبعد نجاح الدخول يرجع مباشرة إلى شاشة السوق.
  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColor.primaryColor),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'يجب أن تكون مسجّلاً بحسابك (الطالب) كي تتمكن من عرض غرض في سوق الطلبة، حمايةً للسوق من الإعلانات المزيفة.\n\nسيتم إرجاعك إلى السوق تلقائياً بعد الدخول.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('لاحقاً', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.w900)),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              // بعد الرجوع من شاشة الدخول: تحديث القائمة والعداد إن كان قد سجّل الدخول
              if (mounted && context.read<UserProvider>().isLoggedIn) {
                _loadItems();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterBottomSheet(
        initialCategory: _selectedCategory,
        initialShowMyItems: _showOnlyMyItems,
        categories: _categories,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedCategory = result['category'] as String;
        _showOnlyMyItems = result['showMyItems'] as bool;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final matricule = user.matricule;

    var filtered = _items.where((i) {
      if (_showOnlyMyItems && i.matricule != matricule) return false;
      if (_selectedCategory == 'free' && !i.isFree && i.price > 0) return false;
      if (_selectedCategory != 'all' &&
          _selectedCategory != 'free' &&
          i.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = i.title.toLowerCase().contains(q);
        final matchDesc = i.description.toLowerCase().contains(q);
        final matchPav = i.pavilion.toLowerCase().contains(q);
        final matchSeller = i.sellerName.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchPav && !matchSeller) return false;
      }
      return true;
    }).toList();

    final activeFilterCount =
        (_selectedCategory != 'all' ? 1 : 0) + (_showOnlyMyItems ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'سوق الطلبة',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
            tooltip: 'تحديث',
            onPressed: _loadItems,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItemDialog,
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.black,
        elevation: 8,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          _userActiveCount >= 3 ? ' ($_userActiveCount/3) الحد' : 'عرض غرض $_userActiveCount/3',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        backgroundColor: AppColor.surfaceColor,
        strokeWidth: 2.5,
        onRefresh: _loadItems,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColor.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'ابحث في السوق...',
                          hintStyle: TextStyle(color: AppColor.textMuted, fontSize: 13),
                          prefixIcon:
                              const Icon(Icons.search, size: 20, color: AppColor.primaryColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? InkWell(
                                  onTap: () => setState(() => _searchQuery = ''),
                                  child: const Icon(Icons.close, size: 18, color: Colors.white54),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: _showFilterSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: activeFilterCount > 0
                                ? AppColor.primaryColor.withValues(alpha: 0.15)
                                : AppColor.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: activeFilterCount > 0
                                  ? AppColor.primaryColor
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: activeFilterCount > 0
                                ? AppColor.primaryColor
                                : AppColor.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                      if (activeFilterCount > 0)
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColor.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$activeFilterCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${filtered.length}',
                        style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'غرض متوفر',
                        style: TextStyle(color: AppColor.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  if (activeFilterCount > 0)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'all';
                          _showOnlyMyItems = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.wrongColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.clear_all, size: 12, color: AppColor.wrongColor),
                            SizedBox(width: 3),
                            Text(
                              'مسح الفلاتر',
                              style: TextStyle(
                                color: AppColor.wrongColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColor.primaryColor))
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColor.surfaceColor,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    _showOnlyMyItems
                                        ? Icons.inventory_2_outlined
                                        : Icons.shopping_bag_outlined,
                                    size: 54,
                                    color: AppColor.primaryColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _showOnlyMyItems
                                      ? 'لم تقم بعرض أي غرض بعد'
                                      : 'لا توجد أغراض في هذا القسم',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showOnlyMyItems
                                      ? 'يمكنك عرض 3 أغراض في نفس الوقت'
                                      : 'كن أول من ينشر غرضاً في السوق',
                                  style:
                                      TextStyle(color: AppColor.textMuted, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                if (!_showOnlyMyItems)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primaryColor,
                                      foregroundColor: Colors.black,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('عرض غرض جديد',
                                        style: TextStyle(fontWeight: FontWeight.w900)),
                                    onPressed: _openAddItemDialog,
                                  ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isOwner = item.matricule == matricule;
                            final isAdmin = user.appRole.canProgramApp;

                            return _CompactProductCard(
                              item: item,
                              isOwner: isOwner,
                              isAdmin: isAdmin,
                              onTap: () => _openItemDetails(item),
                              onLongPress: isOwner ? () => _openEditItemDialog(item) : null,
                              onDelete: () => _confirmDeleteItem(item),
                              onToggleSold: () => _toggleSoldStatus(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterItem {
  final String id;
  final String label;
  final IconData icon;
  const _CategoryFilterItem(this.id, this.label, this.icon);
}

/// =====================================================
/// بطاقة منتج صغيرة (PRO STORE STYLE - مصغرة و احترافية)
/// =====================================================
class _CompactProductCard extends StatelessWidget {
  final MarketplaceItem item;
  final bool isOwner;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onToggleSold;

  const _CompactProductCard({
    required this.item,
    required this.isOwner,
    required this.isAdmin,
    required this.onTap,
    this.onLongPress,
    required this.onDelete,
    required this.onToggleSold,
  });

  @override
  Widget build(BuildContext context) {
    final isSold = item.isSold;
    final isFree = !isSold && item.isFree;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSold
              ? Colors.white.withValues(alpha: 0.05)
              : (isFree
                  ? AppColor.correctColor.withValues(alpha: 0.2)
                  : AppColor.primaryColor.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: AppColor.primaryColor.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== صورة المنتج =====
              AspectRatio(
                aspectRatio: 1.05,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        color: AppColor.cardLight,
                        child: item.hasImages
                            ? Image.network(
                                item.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(item.categoryIcon,
                                      color: item.categoryColor.withValues(alpha: 0.5), size: 38),
                                ),
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColor.primaryColor)),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(item.categoryIcon,
                                    color: item.categoryColor.withValues(alpha: 0.65),
                                    size: 40),
                              ),
                      ),
                    ),

                    // مباع
                    if (isSold)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AppColor.primaryColor, AppColor.secondaryColor]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 11, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('مباع',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // مجاني
                    if (isFree)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColor.correctColor, AppColor.secondaryColor]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🎁 مجاني',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),

                    // إعلاني (للمالك)
                    if (isOwner && !isSold)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.4)),
                          ),
                          child: const Text('إعلاني',
                              style: TextStyle(
                                  color: AppColor.primaryColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),

                    // عدد الصور
                    if (!isSold && item.images.length > 1)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('📸${item.images.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),

              // ===== معلومات المنتج =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان المنتج
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // السعر
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isFree && !isSold)
                            Text('دج ',
                                style: TextStyle(
                                    color: AppColor.primaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          Text(
                            isFree
                                ? 'مجاني'
                                : isSold
                                    ? 'غير متوفر'
                                    : (item.price.truncateToDouble() == item.price
                                        ? item.price.toInt().toString()
                                        : item.price.toStringAsFixed(2)),
                            style: TextStyle(
                              color: isSold
                                  ? Colors.white38
                                  : isFree
                                      ? AppColor.correctColor
                                      : AppColor.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // بائع فقط (إزالة الجناح ورقم الغرفة من الكارت)
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 10, color: AppColor.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.sellerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColor.textMuted, fontSize: 10),
                            ),
                          ),
                          if (isOwner)
                            Icon(Icons.edit_square,
                                size: 10, color: AppColor.primaryColor.withValues(alpha: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================================================
/// نافذة الفلاتر (Bottom Sheet) بدل شريط الفئات
/// =====================================================
class _FilterBottomSheet extends StatefulWidget {
  final String initialCategory;
  final bool initialShowMyItems;
  final List<_CategoryFilterItem> categories;

  const _FilterBottomSheet({
    required this.initialCategory,
    required this.initialShowMyItems,
    required this.categories,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _category;
  late bool _showMyItems;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _showMyItems = widget.initialShowMyItems;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Center(
            child: Text(
              'تصفية النتائج',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 22),

          // أغراضي الخاصة
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: AppColor.primaryColor.withValues(alpha: 0.4),
            activeThumbColor: AppColor.primaryColor,
            value: _showMyItems,
            onChanged: (v) => setState(() => _showMyItems = v),
            title: Row(
              children: const [
                Icon(Icons.inventory_2_outlined,
                    size: 19, color: AppColor.primaryColor),
                SizedBox(width: 10),
                Text('أغراضي الخاصة فقط',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white10),
          const SizedBox(height: 14),

          // فئة المنتجات
          const Text('الصنف:',
              style: TextStyle(
                  color: AppColor.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final selected = _category == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _category = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColor.primaryColor, AppColor.secondaryColor])
                        : null,
                    color: selected ? null : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColor.primaryColor
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon,
                          size: 14,
                          color: selected ? Colors.black : AppColor.textSecondary),
                      const SizedBox(width: 5),
                      Text(cat.label,
                          style: TextStyle(
                              color: selected ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // زر التطبيق
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.black,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.pop(context, {
                'category': _category,
                'showMyItems': _showMyItems,
              });
            },
            child: const Text('تطبيق الفلاتر',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// =====================================================
/// صفحة تفاصيل المنتج الكاملة (FULL SCREEN)
/// =====================================================
class _ProductDetailScreen extends StatefulWidget {
  final MarketplaceItem item;
  final bool isOwner;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onToggleSold;
  final VoidCallback? onEdit;

  const _ProductDetailScreen({
    required this.item,
    required this.isOwner,
    required this.isAdmin,
    required this.onDelete,
    required this.onToggleSold,
    this.onEdit,
  });

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  /// مشاركة الغرض عبر قائمة المشاركة الأصلية للهاتف (WhatsApp, Messenger, SMS...)
  Future<void> _shareProduct() async {
    final item = widget.item;
    final id = Uri.encodeComponent(item.id);
    const site = 'https://cube3-dz.pages.dev';
    final link = '$site/p/$id';

    final priceLine = item.isSold
        ? '✅ تم البيع'
        : item.isFree
            ? '🎁 مجاني / إعارة'
            : '💰 السعر: ${item.formattedPrice}';

    final text = '📢 ${item.title}\n'
        '$priceLine\n'
        '🛒 سوق الطلبة — تطبيق cube3\n'
        '🔗 $link';

    try {
      await SharePlus.instance.share(ShareParams(text: text, title: item.title));
    } catch (_) {
      // احتياط: نسخ الرابط إذا فشلت قائمة المشاركة
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ رابط الغرض'),
          backgroundColor: AppColor.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('تفاصيل الغرض',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة الغرض',
            icon: const Icon(Icons.share_outlined, color: AppColor.primaryColor),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============== معرض الصور (كبير واحترافي + سكرول + نقاط) ==============
            if (widget.item.hasImages)
              Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: widget.item.images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: widget.item.images.length > 1 ? 4 : 0),
                          child: GestureDetector(
                            onTap: () => ImageViewerDialog.show(
                              context,
                              images: widget.item.images,
                              initialIndex: idx,
                              title: widget.item.title,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColor.cardLight,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  widget.item.images[idx],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(widget.item.categoryIcon,
                                        color: widget.item.categoryColor.withValues(alpha: 0.5),
                                        size: 60),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.item.images.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColor.primaryColor : Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اسحب يساراً ويميناً لعرض باقي الصور',
                    style: TextStyle(color: AppColor.textMuted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (!widget.item.hasImages)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColor.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(widget.item.categoryIcon,
                      color: widget.item.categoryColor.withValues(alpha: 0.6), size: 70),
                ),
              ),
            const SizedBox(height: 18),

            // شارات الفئة + الحالة
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.item.categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.item.categoryIcon, size: 13, color: widget.item.categoryColor),
                      const SizedBox(width: 5),
                      Text(widget.item.categoryLabelAr,
                          style: TextStyle(
                              color: widget.item.categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                if (widget.item.isSold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColor.correctColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 13, color: AppColor.correctColor),
                        SizedBox(width: 5),
                        Text('تم البيع',
                            style: TextStyle(
                                color: AppColor.correctColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                if (widget.item.isFree && !widget.item.isSold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColor.correctColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard, size: 13, color: AppColor.correctColor),
                        SizedBox(width: 5),
                        Text('مجاني / إعارة',
                            style: TextStyle(
                                color: AppColor.correctColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // العنوان
            Text(widget.item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2)),
            const SizedBox(height: 10),

            // السعر
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sell_rounded, color: AppColor.primaryColor, size: 30),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('السعر',
                          style: TextStyle(color: AppColor.textMuted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(widget.item.formattedPrice,
                          style: TextStyle(
                              color: widget.item.isFree || widget.item.isSold
                                  ? AppColor.correctColor
                                  : AppColor.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // الوصف
            if (widget.item.description.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppColor.primaryColor, size: 16),
                        SizedBox(width: 6),
                        Text('التفاصيل والحالة',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(widget.item.description,
                        style: TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 13,
                            height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // معلومات البائع
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColor.primaryColor,
                        radius: 22,
                        child:
                            const Icon(Icons.person, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.sellerName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(
                              widget.item.pavilion.isNotEmpty
                                  ? '${widget.item.pavilion}${widget.item.roomNumber.isNotEmpty ? " · غرفة ${widget.item.roomNumber}" : ""}'
                                  : 'طالب بالإقامة الجامعية',
                              style: TextStyle(color: AppColor.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // أزرار التواصل
            if (!widget.item.isSold) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.correctColor,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('اتصال',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () {
                        launchUrl(Uri.parse('tel:${widget.item.cleanPhone}'),
                            mode: LaunchMode.externalApplication);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('واتساب',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () {
                        final clean = widget.item.cleanPhone;
                        final num = clean.startsWith('0') ? '213${clean.substring(1)}' : clean;
                        final uri = Uri.parse(
                            'https://wa.me/$num?text=السلام عليكم بخصوص إعلانك: ${Uri.encodeComponent(widget.item.title)}');
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // أزرار المالك / المدير
            if (widget.isOwner || widget.isAdmin) ...[
              const SizedBox(height: 6),
              const Divider(color: Colors.white10),
              const SizedBox(height: 14),
              const Text('إدارة الإعلان',
                  style: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (widget.isOwner && widget.onEdit != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor.withValues(alpha: 0.15),
                        foregroundColor: AppColor.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side:
                                BorderSide(color: AppColor.primaryColor.withValues(alpha: 0.4))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      icon: const Icon(Icons.edit_square, size: 17),
                      label: const Text('تعديل الإعلان',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                      onPressed: widget.onEdit,
                    ),
                  if (widget.isOwner)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.warningColor.withValues(alpha: 0.15),
                        foregroundColor: AppColor.warningColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                                color: AppColor.warningColor.withValues(alpha: 0.5))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      icon: Icon(widget.item.isSold ? Icons.refresh : Icons.check_circle,
                          size: 17),
                      label: Text(widget.item.isSold ? 'إعادة العرض' : 'تم البيع',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12.5)),
                      onPressed: widget.onToggleSold,
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.wrongColor.withValues(alpha: 0.15),
                      foregroundColor: AppColor.wrongColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: AppColor.wrongColor.withValues(alpha: 0.5))),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: Text(widget.isAdmin && !widget.isOwner ? 'حذف (إدارة)' : 'حذف الإعلان',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12.5)),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// =====================================================
/// صفحة إضافة غرض جديد (FULL SCREEN - واجهة كاملة PRO)
/// =====================================================
class _AddMarketplaceItemPage extends StatefulWidget {
  final MarketplaceService marketplaceService;
  final FacilityService facilityService;
  final VoidCallback onSuccess;

  const _AddMarketplaceItemPage({
    required this.marketplaceService,
    required this.facilityService,
    required this.onSuccess,
  });

  @override
  State<_AddMarketplaceItemPage> createState() => _AddMarketplaceItemPageState();
}

class _AddMarketplaceItemPageState extends State<_AddMarketplaceItemPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pavilionController = TextEditingController();
  final _roomController = TextEditingController();

  String _category = 'books';
  bool _isFree = false;
  final List<String> _images = [];
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _phoneController.text = '';
    _pavilionController.text = '';
    _roomController.text = user.roomNumber ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _pavilionController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ الحد الأقصى هو 3 صور لكل غرض')),
      );
      return;
    }
    try {
      final picked = await pickPostImage();
      if (picked == null) return;
      setState(() => _uploadingImage = true);
      final url = await widget.facilityService.uploadFacilityImage(
        picked.bytes,
        mime: picked.mime,
      );
      if (mounted) {
        setState(() {
          _images.add(url);
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanUploadErrorMessage(e)), backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  Future<void> _removeImage(int idx) async {
    final url = _images[idx];
    setState(() => _images.removeAt(idx));
    widget.facilityService.deleteMediaFromStorage(url);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final phone = _phoneController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان الغرض'), backgroundColor: AppColor.warningColor),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم هاتفك للتواصل'), backgroundColor: AppColor.warningColor),
      );
      return;
    }
    final user = context.read<UserProvider>();
    final double price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);
    setState(() => _submitting = true);
    try {
      final item = MarketplaceItem(
        id: '',
        matricule: user.matricule.isNotEmpty ? user.matricule : 'guest',
        sellerName: user.fullNameAr.isNotEmpty ? user.fullNameAr : 'طالب بالإقامة',
        sellerPhone: phone,
        pavilion: _pavilionController.text.trim(),
        roomNumber: _roomController.text.trim(),
        title: title,
        description: _descController.text.trim(),
        price: price,
        isFree: _isFree,
        category: _category,
        images: _images,
      );
      await widget.marketplaceService.createItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📢 تم نشر الغرض بنجاح في سوق الطلبة'), backgroundColor: AppColor.correctColor),
        );
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('عرض غرض جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primaryColor))
                  : const Text('نشر 🚀',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, color: AppColor.primaryColor, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColor.primaryColor, AppColor.secondaryColor]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.sell_rounded, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('نشر إعلانك في السوق',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('حدد تفاصيل الغرض جيداً للبيع السريع 🔥',
                            style: TextStyle(color: AppColor.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('العنوان والوصف', Icons.drive_file_rename_outline),
            const SizedBox(height: 10),
            _proField(
              controller: _titleController,
              label: 'عنوان الغرض *',
              hint: 'مثال: كتاب الخوارزميات، ثلاجة صغيرة',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),
            _proField(
              controller: _descController,
              label: 'تفاصيل وحالة الغرض',
              hint: 'مثال: كتاب بحالة ممتازة، بدون إخداش / ثلاجة صغيرة تعمل 100%',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            _sectionLabel('التصنيف والسعر', Icons.price_change_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: AppColor.surfaceColor,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColor.primaryColor),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'books', child: Text('📚 كتب ومراجع جامعية')),
                    DropdownMenuItem(value: 'clothing', child: Text('👕 ألبسة وملابس')),
                    DropdownMenuItem(value: 'appliances', child: Text('🛏️ مستلزمات الغرف')),
                    DropdownMenuItem(value: 'electronics', child: Text('💻 أجهزة وإلكترونيات')),
                    DropdownMenuItem(value: 'other', child: Text('📦 أغراض أخرى')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'books'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Row(
                children: const [
                  Icon(Icons.card_giftcard, color: AppColor.correctColor, size: 18),
                  SizedBox(width: 8),
                  Text('غرض مجاني / للإعارة',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              value: _isFree,
              activeThumbColor: AppColor.correctColor,
              activeTrackColor: AppColor.correctColor.withValues(alpha: 0.4),
              onChanged: (v) => setState(() => _isFree = v),
            ),
            const SizedBox(height: 8),
            if (!_isFree)
              _proField(
                controller: _priceController,
                label: 'السعر (دينار جزائري)',
                hint: 'مثال: 1500',
                icon: Icons.payments_rounded,
                keyboard: TextInputType.number,
                suffix: 'دج',
              ),
            if (!_isFree) const SizedBox(height: 24),
            if (_isFree) const SizedBox(height: 16),

            _sectionLabel('معلومات التواصل', Icons.call),
            const SizedBox(height: 10),
            _proField(
              controller: _phoneController,
              label: 'رقم الهاتف *',
              hint: '0555123456',
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              ltr: true,
              iconColor: AppColor.correctColor,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _proField(
                    controller: _pavilionController,
                    label: 'الجناح',
                    hint: 'مثال: جناح C',
                    icon: Icons.apartment_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _proField(
                    controller: _roomController,
                    label: 'رقم الغرفة (اختياري)',
                    hint: '24',
                    icon: Icons.door_front_door_outlined,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('الصور (${_images.length}/3)', Icons.photo_library_rounded),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _uploadingImage || _images.length >= 3 ? null : _pickImage,
              child: Container(
                height: _images.isNotEmpty ? 110 : 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _images.isEmpty
                          ? AppColor.primaryColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                      style: _images.isEmpty ? BorderStyle.solid : BorderStyle.solid),
                ),
                child: _images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _uploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColor.primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.add_a_photo_outlined,
                                        color: AppColor.primaryColor, size: 28),
                                  ),
                            const SizedBox(height: 10),
                            Text(_uploadingImage ? 'جاري رفع الصورة...' : 'اضغط لإضافة صور للغرض',
                                style: TextStyle(
                                    color: _uploadingImage
                                        ? AppColor.primaryColor
                                        : AppColor.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text('حتى 3 صور - الصورة الأولى هي غلاف الإعلان',
                                style: TextStyle(color: AppColor.textMuted, fontSize: 10.5)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + (_images.length < 3 ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          if (i == _images.length) {
                            return GestureDetector(
                              onTap: _uploadingImage ? null : _pickImage,
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColor.primaryColor.withValues(alpha: 0.35)),
                                ),
                                child: _uploadingImage
                                    ? const Center(
                                        child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                color: AppColor.primaryColor, strokeWidth: 2)))
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined,
                                              color: AppColor.primaryColor, size: 24),
                                          SizedBox(height: 4),
                                          Text('إضافة',
                                              style: TextStyle(
                                                  color: AppColor.primaryColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5)),
                                        ],
                                      ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_images[i],
                                    width: 90, height: 90, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColor.wrongColor.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 50),

            // زر النشر الأساسي (PRO BIG BUTTON)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: AppColor.primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.publish_rounded, size: 20),
                label: Text(_submitting ? 'جاري النشر...' : 'نشر الإعلان في السوق 🚀',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== UI Helpers ======
  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColor.primaryColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _proField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLines = 1,
    TextInputType? keyboard,
    String? suffix,
    bool ltr = false,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        textDirection: ltr ? TextDirection.ltr : null,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColor.textMuted, fontSize: 12),
          hintStyle: TextStyle(color: AppColor.textMuted.withValues(alpha: 0.7), fontSize: 12),
          prefixIcon: Icon(icon, size: 19, color: iconColor ?? AppColor.primaryColor),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: AppColor.textSecondary, fontWeight: FontWeight.w800),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines! > 1 ? 14 : 12),
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
      ),
    );
  }
}

/// =====================================================
/// صفحة تعديل بيانات الغرض (FULL SCREEN PRO)
/// =====================================================
class _EditMarketplaceItemPage extends StatefulWidget {
  final MarketplaceItem item;
  final MarketplaceService marketplaceService;
  final FacilityService facilityService;
  final VoidCallback onSuccess;

  const _EditMarketplaceItemPage({
    required this.item,
    required this.marketplaceService,
    required this.facilityService,
    required this.onSuccess,
  });

  @override
  State<_EditMarketplaceItemPage> createState() => _EditMarketplaceItemPageState();
}

class _EditMarketplaceItemPageState extends State<_EditMarketplaceItemPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pavilionController;
  late final TextEditingController _roomController;

  late String _category;
  late bool _isFree;
  late List<String> _images;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descController = TextEditingController(text: widget.item.description);
    _priceController = TextEditingController(
      text: widget.item.price > 0
          ? (widget.item.price.truncateToDouble() == widget.item.price
              ? widget.item.price.toInt().toString()
              : widget.item.price.toStringAsFixed(2))
          : '',
    );
    _phoneController = TextEditingController(text: widget.item.sellerPhone);
    _pavilionController = TextEditingController(text: widget.item.pavilion);
    _roomController = TextEditingController(text: widget.item.roomNumber);
    _category = widget.item.category;
    _isFree = widget.item.isFree;
    _images = List<String>.from(widget.item.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _pavilionController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ الحد الأقصى هو 3 صور لكل غرض')),
      );
      return;
    }
    try {
      final picked = await pickPostImage();
      if (picked == null) return;
      setState(() => _uploadingImage = true);
      final url = await widget.facilityService.uploadFacilityImage(
        picked.bytes,
        mime: picked.mime,
      );
      if (mounted) {
        setState(() {
          _images.add(url);
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanUploadErrorMessage(e)), backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  Future<void> _removeImage(int idx) async {
    final url = _images[idx];
    setState(() => _images.removeAt(idx));
    widget.facilityService.deleteMediaFromStorage(url);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final phone = _phoneController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان الغرض'), backgroundColor: AppColor.warningColor),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم هاتفك للتواصل'), backgroundColor: AppColor.warningColor),
      );
      return;
    }
    final user = context.read<UserProvider>();
    final double price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);
    setState(() => _submitting = true);
    try {
      final updated = widget.item.copyWith(
        matricule: user.matricule.isNotEmpty ? user.matricule : null,
        sellerName: user.fullNameAr.isNotEmpty ? user.fullNameAr : null,
        sellerPhone: phone,
        pavilion: _pavilionController.text.trim(),
        roomNumber: _roomController.text.trim(),
        title: title,
        description: _descController.text.trim(),
        price: price,
        isFree: _isFree,
        category: _category,
        images: _images,
      );
      await widget.marketplaceService.updateItem(widget.item.id, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✏️ تم تعديل بيانات الغرض بنجاح'), backgroundColor: AppColor.correctColor),
        );
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColor.wrongColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('تعديل بيانات الغرض',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColor.primaryColor))
                  : const Text('حفظ 💾',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColor.primaryColor,
                          fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColor.primaryColor, AppColor.secondaryColor]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.edit_square, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تحديث بيانات الإعلان',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('عدّل معلومات الغرض كما تشاء',
                            style: TextStyle(color: AppColor.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabelEdit('العنوان والوصف', Icons.drive_file_rename_outline),
            const SizedBox(height: 10),
            _editField(
              controller: _titleController,
              label: 'عنوان الغرض *',
              hint: 'مثال: كتاب الخوارزميات، ثلاجة صغيرة',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),
            _editField(
              controller: _descController,
              label: 'تفاصيل وحالة الغرض',
              hint: 'مثال: كتاب بحالة ممتازة، بدون إخداش',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            _sectionLabelEdit('التصنيف والسعر', Icons.price_change_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: AppColor.surfaceColor,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColor.primaryColor),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'books', child: Text('📚 كتب ومراجع جامعية')),
                    DropdownMenuItem(value: 'clothing', child: Text('👕 ألبسة وملابس')),
                    DropdownMenuItem(value: 'appliances', child: Text('🛏️ مستلزمات الغرف')),
                    DropdownMenuItem(value: 'electronics', child: Text('💻 أجهزة وإلكترونيات')),
                    DropdownMenuItem(value: 'other', child: Text('📦 أغراض أخرى')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'books'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Row(
                children: const [
                  Icon(Icons.card_giftcard, color: AppColor.correctColor, size: 18),
                  SizedBox(width: 8),
                  Text('غرض مجاني / للإعارة',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              value: _isFree,
              activeThumbColor: AppColor.correctColor,
              activeTrackColor: AppColor.correctColor.withValues(alpha: 0.4),
              onChanged: (v) => setState(() => _isFree = v),
            ),
            const SizedBox(height: 8),
            if (!_isFree)
              _editField(
                controller: _priceController,
                label: 'السعر (دينار جزائري)',
                hint: 'مثال: 1500',
                icon: Icons.payments_rounded,
                keyboard: TextInputType.number,
                suffix: 'دج',
              ),
            if (!_isFree) const SizedBox(height: 24),
            if (_isFree) const SizedBox(height: 16),

            _sectionLabelEdit('معلومات التواصل', Icons.call),
            const SizedBox(height: 10),
            _editField(
              controller: _phoneController,
              label: 'رقم الهاتف *',
              hint: '0555123456',
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              ltr: true,
              iconColor: AppColor.correctColor,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _editField(
                    controller: _pavilionController,
                    label: 'الجناح',
                    hint: 'مثال: جناح C',
                    icon: Icons.apartment_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _editField(
                    controller: _roomController,
                    label: 'رقم الغرفة (اختياري)',
                    hint: '24',
                    icon: Icons.door_front_door_outlined,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabelEdit('الصور (${_images.length}/3)', Icons.photo_library_rounded),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _uploadingImage || _images.length >= 3 ? null : _pickImage,
              child: Container(
                height: _images.isNotEmpty ? 110 : 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _images.isEmpty
                          ? AppColor.primaryColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5),
                ),
                child: _images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _uploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: AppColor.primaryColor, strokeWidth: 2))
                                : Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColor.primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.add_a_photo_outlined,
                                        color: AppColor.primaryColor, size: 28),
                                  ),
                            const SizedBox(height: 10),
                            Text(_uploadingImage ? 'جاري رفع الصورة...' : 'اضغط لإضافة صور للغرض',
                                style: TextStyle(
                                    color: _uploadingImage
                                        ? AppColor.primaryColor
                                        : AppColor.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text('حتى 3 صور - الصورة الأولى هي غلاف الإعلان',
                                style: TextStyle(color: AppColor.textMuted, fontSize: 10.5)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + (_images.length < 3 ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          if (i == _images.length) {
                            return GestureDetector(
                              onTap: _uploadingImage ? null : _pickImage,
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColor.primaryColor.withValues(alpha: 0.35)),
                                ),
                                child: _uploadingImage
                                    ? const Center(
                                        child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                color: AppColor.primaryColor, strokeWidth: 2)))
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined,
                                              color: AppColor.primaryColor, size: 24),
                                          SizedBox(height: 4),
                                          Text('إضافة',
                                              style: TextStyle(
                                                  color: AppColor.primaryColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5)),
                                        ],
                                      ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_images[i],
                                    width: 90, height: 90, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColor.wrongColor.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: AppColor.primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_submitting ? 'جاري الحفظ...' : 'حفظ التعديلات 💾',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabelEdit(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColor.primaryColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLines = 1,
    TextInputType? keyboard,
    String? suffix,
    bool ltr = false,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        textDirection: ltr ? TextDirection.ltr : null,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColor.textMuted, fontSize: 12),
          hintStyle: TextStyle(color: AppColor.textMuted.withValues(alpha: 0.7), fontSize: 12),
          prefixIcon: Icon(icon, size: 19, color: iconColor ?? AppColor.primaryColor),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: AppColor.textSecondary, fontWeight: FontWeight.w800),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines! > 1 ? 14 : 12),
        ),
      ),
    );
  }
}
