import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import '../../theme/theme.dart';
import '../../services/medical_orders_service.dart';
import '../../services/reservation_service.dart';

/// لوحة الطلبات والحجوزات: أوامر المصلحة الطبية + حجوزات الإطعام.
/// تظهر هنا فقط (لا تُعرض للطلبة).
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final MedicalOrdersService _med = MedicalOrdersService();

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final o = await _med.allOrders();
    final r = await ReservationService.fetchAllForAdmin();
    if (mounted) {
      setState(() {
        _orders = o;
        _reservations = r;
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await _med.setStatus(id, status);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'تم تحديث الطلب إلى: ${MedicalOrdersService.statusLabel(status)}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التحديث — تحقق من الاتصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('الطلبات والحجوزات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColor.primaryColor,
          tabs: [
            Tab(text: 'طبية (${_orders.length})'),
            Tab(text: 'إطعام (${_reservations.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        onRefresh: _reload,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColor.primaryColor))
            : TabBarView(
                controller: _tab,
                children: [
                  _medicalList(),
                  _cateringList(),
                ],
              ),
      ),
    );
  }

  Widget _medicalList() {
    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.medical_services_outlined,
                size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('لا توجد طلبات طبية',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final o = _orders[i];
        final status = (o['status'] ?? 'pending').toString();
        final color = status == 'done'
            ? AppColor.correctColor
            : status == 'cancelled'
                ? Colors.redAccent
                : status == 'confirmed'
                    ? Colors.blueAccent
                    : Colors.orangeAccent;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.surfaceColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (o['name'] ?? '').toString().isEmpty
                          ? (o['matricule'] ?? '').toString()
                          : (o['name'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        MedicalOrdersService.statusLabel(status),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${o['specialty'] ?? ''} • ${o['date'] ?? ''}',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              if ((o['notes'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    (o['notes'] ?? '').toString(),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (status == 'pending')
                    _stBtn('تأكيد', Colors.blueAccent,
                        () => _setStatus((o['id'] ?? '').toString(), 'confirmed')),
                  if (status != 'done')
                    _stBtn('تم ✅', AppColor.correctColor,
                        () => _setStatus((o['id'] ?? '').toString(), 'done')),
                  if (status != 'cancelled')
                    _stBtn('إلغاء', Colors.redAccent,
                        () => _setStatus((o['id'] ?? '').toString(), 'cancelled')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stBtn(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _cateringList() {
    if (_reservations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined,
                size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('لا توجد حجوزات إطعام',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = _reservations[i];
        DateTime? exp;
        try {
          exp = DateTime.parse((r['expiresAt'] ?? '').toString());
        } catch (_) {}
        final active = exp != null && now.isBefore(exp);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.surfaceColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: (active
                        ? AppColor.correctColor
                        : Colors.white10)
                    .withValues(alpha: active ? 0.3 : 1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (active
                        ? AppColor.correctColor
                        : Colors.white24)
                    .withValues(alpha: 0.12),
                child: Icon(Icons.person_outline,
                    color: active
                        ? AppColor.correctColor
                        : Colors.white38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (r['name'] ?? '').toString().isEmpty
                          ? (r['matricule'] ?? '').toString()
                          : (r['name'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ينتهي: ${(r['expiresAt'] ?? '').toString().substring(0, 10)}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(active ? 'نشط ✅' : 'منتهي',
                  style: TextStyle(
                      color: active
                          ? AppColor.correctColor
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
