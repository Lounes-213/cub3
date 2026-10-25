import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/theme.dart';
import '../../core/auth/app_roles.dart';
import '../../core/utils/photo_utils.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedRoleFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(UserModel u) {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return true;
    return u.fullNameAr.contains(q) ||
        u.username.contains(q) ||
        u.registrationNumber.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        backgroundColor: AppColor.surfaceColor,
        title: const Text('إدارة وصلاحيات المستخدمين', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColor.primaryColor),
            onPressed: _showAddProfileDialog,
            tooltip: 'إضافة حساب جديد',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بحث احترافي (لا تُعرض الحسابات مباشرة بدون تصفية)
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم / المستخدم / رقم التسجيل...',
                      hintStyle: const TextStyle(
                          color: Colors.white24, fontSize: 12),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColor.primaryColor, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white38, size: 18),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColor.backgroundColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'all'),
                        _buildFilterChip('المدراء', 'admin'),
                        _buildFilterChip('المشرفون', 'staf'),
                        _buildFilterChip('العمال', 'trav'),
                        _buildFilterChip('الطلاب', 'etud'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  
                  // Profiles Realtime List
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService().getProfilesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: AppColor.primaryColor),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('خطأ في تحميل الحسابات', style: TextStyle(color: Colors.redAccent)));
                      }
                      
                      final profiles = snapshot.data ?? [];
                      final allUsers =
                          profiles.map((p) => UserModel.fromMap(p)).toList();
                      final filteredProfiles = allUsers.where((u) {
                        final roleOk = _selectedRoleFilter == 'all' ||
                            u.role == _selectedRoleFilter;
                        return roleOk && _matchesSearch(u);
                      }).toList();

                      if (filteredProfiles.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                Icon(Icons.people_outline, size: 40, color: Colors.white24),
                                SizedBox(height: 12),
                                Text('لا توجد حسابات مطابقة للبحث', style: TextStyle(color: Colors.white38, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(allUsers),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProfiles.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: Colors.white10, height: 16),
                            itemBuilder: (context, index) {
                              final user = filteredProfiles[index];
                              return _buildProfileItem(user);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedRoleFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoleFilter = filterKey;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.redAccent : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<UserModel> all) {
    int count(String r) => all.where((u) => u.role == r).length;
    Widget stat(String label, int n, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text('$n',
                    style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat('الكل', all.length, Colors.white70),
        const SizedBox(width: 8),
        stat('مدراء', count('admin'), Colors.redAccent),
        const SizedBox(width: 8),
        stat('مشرفون', count('staf'), Colors.blueAccent),
        const SizedBox(width: 8),
        stat('عمال', count('trav'), Colors.orangeAccent),
        const SizedBox(width: 8),
        stat('طلبة', count('etud'), AppColor.primaryColor),
      ],
    );
  }

  /// صف مضغوط: الاسم + الدور فقط — التفاصيل تُكشف عند الضغط (احترافية وخصوصية).
  Widget _buildProfileItem(UserModel user) {
    final fullName = user.fullNameAr;
    final role = user.role;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetailDialog(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      _getRoleColor(role).withValues(alpha: 0.1),
                  child: Builder(
                    builder: (context) {
                      final photoBytes = tryDecodePhoto(user.photo);
                      if (photoBytes == null) {
                        return Text(
                          fullName.isNotEmpty ? fullName.substring(0, 1) : 'U',
                          style: TextStyle(
                              color: _getRoleColor(role),
                              fontWeight: FontWeight.bold),
                        );
                      }
                      return ClipOval(
                        child: Image.memory(
                          photoBytes,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(
                            fullName.isNotEmpty ? fullName.substring(0, 1) : 'U',
                            style: TextStyle(
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isActive
                          ? AppColor.correctColor
                          : Colors.redAccent,
                      border: Border.all(
                          color: AppColor.surfaceColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? '—' : fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          _getRoleColor(role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRoleLabel(role),
                      style: TextStyle(
                          color: _getRoleColor(role),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.visibility_outlined,
                size: 18, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  /// بطاقة التفاصيل الكاملة (تُفتح عند الضغط فقط).
  void _showDetailDialog(UserModel user) {
    final bytes = tryDecodePhoto(user.photo);
    Widget row(String label, String value, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  _getRoleColor(user.role).withValues(alpha: 0.12),
              backgroundImage:
                  bytes != null ? MemoryImage(bytes) : null,
              child: bytes == null
                  ? Text(
                      user.fullNameAr.isNotEmpty
                          ? user.fullNameAr.substring(0, 1)
                          : 'U',
                      style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullNameAr.isEmpty ? '—' : user.fullNameAr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.isActive ? '● حساب نشط' : '● حساب معطل',
                    style: TextStyle(
                        color: user.isActive
                            ? AppColor.correctColor
                            : Colors.redAccent,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.white10),
              row('اسم المستخدم', user.username),
              row('الدور', _getRoleLabel(user.role),
                  valueColor: _getRoleColor(user.role)),
              row('رقم التسجيل', user.registrationNumber),
              row('المستوى', user.levelAr),
              row('الطور', user.cycleAr),
              if ((user.dateOfBirth ?? '').isNotEmpty)
                row('تاريخ الميلاد', user.dateOfBirth!),
              if ((user.roomNumber ?? '').isNotEmpty)
                row('رقم الغرفة', user.roomNumber!,
                    valueColor: AppColor.primaryColor),
              if ((user.residentSince ?? '').isNotEmpty)
                row('مقيم منذ', user.residentSince!),
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الحساب مفعّل',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  Switch(
                    activeThumbColor: _getRoleColor(user.role),
                    value: user.isActive,
                    onChanged: user.role == 'admin'
                        ? null
                        : (val) async {
                            final key = user.registrationNumber.isNotEmpty
                                ? user.registrationNumber
                                : user.username;
                            await FirebaseService()
                                .setProfileActive(key, val);
                            if (context.mounted) Navigator.pop(ctx);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showEditProfileDialog(user.toMap());
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('تعديل',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddProfileDialog() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final cycleCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final sinceCtrl = TextEditingController();
    String selectedRole = 'etud';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColor.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text('إضافة حساب جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نوع الصلاحية', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColor.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: AppColor.surfaceColor,
                          value: selectedRole,
                          items: ['admin', 'staf', 'trav', 'etud'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(_getRoleLabel(role), style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogField(nameCtrl, 'الاسم الكامل (بالعربية)', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildDialogField(userCtrl, 'اسم المستخدم (لتسجيل الدخول)', Icons.alternate_email),
                    const SizedBox(height: 12),
                    _buildDialogField(passCtrl, 'كلمة المرور', Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 12),
                    _buildDialogField(regCtrl, 'رقم التسجيل (اختياري)', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(levelCtrl, 'المستوى / المصلحة', Icons.layers_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(cycleCtrl, 'الطور الدراسي / القسم', Icons.school_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(dobCtrl, 'تاريخ الميلاد', Icons.cake_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(roomCtrl, 'رقم الغرفة (يحددها المدير)', Icons.bed_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(sinceCtrl, 'مقيم منذ (مثال: 2024-09-15)', Icons.calendar_month_outlined),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    shape: const StadiumBorder(),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء إدخال الحقول الأساسية: الاسم، اسم المستخدم وكلمة المرور')),
                      );
                      return;
                    }
                    
                    final newProfile = {
                      'username': userCtrl.text.trim(),
                      'password': passCtrl.text.trim(),
                      'fullNameAr': nameCtrl.text.trim(),
                      'role': selectedRole,
                      'registrationNumber': regCtrl.text.trim(),
                      'levelAr': levelCtrl.text.trim(),
                      'cycleAr': cycleCtrl.text.trim(),
                      'dateOfBirth': dobCtrl.text.trim(),
                      'roomNumber': roomCtrl.text.trim(),
                      'residentSince': sinceCtrl.text.trim(),
                      'isActive': true,
                      'photo': null,
                    };

                    final key = regCtrl.text.trim().isNotEmpty ? regCtrl.text.trim() : userCtrl.text.trim();
                    await FirebaseService().saveProfile(key, newProfile);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء الحساب الجديد بنجاح!')),
                      );
                    }
                  },
                  child: const Text('حفظ الحساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(Map<String, dynamic> profile) {
    final nameCtrl = TextEditingController(text: profile['fullNameAr']);
    final passCtrl = TextEditingController(text: profile['password']);
    final regCtrl = TextEditingController(text: profile['registrationNumber']);
    final levelCtrl = TextEditingController(text: profile['levelAr']);
    final cycleCtrl = TextEditingController(text: profile['cycleAr']);
    final dobCtrl = TextEditingController(text: profile['dateOfBirth'] ?? '');
    final roomCtrl =
        TextEditingController(text: (profile['roomNumber'] ?? '').toString());
    final sinceCtrl = TextEditingController(
        text: (profile['residentSince'] ?? '').toString());
    String selectedRole = profile['role'] ?? 'etud';
    final username = profile['username'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColor.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text('تعديل حساب: $username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نوع الصلاحية', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColor.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: profile['role'] == 'admin'
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(_getRoleLabel(selectedRole), style: const TextStyle(color: Colors.white)),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: AppColor.surfaceColor,
                                value: selectedRole,
                                items: ['admin', 'staf', 'trav', 'etud'].map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(_getRoleLabel(role), style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedRole = val);
                                  }
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogField(nameCtrl, 'الاسم الكامل (بالعربية)', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildDialogField(passCtrl, 'كلمة المرور', Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 12),
                    _buildDialogField(regCtrl, 'رقم التسجيل', Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(levelCtrl, 'المستوى / المصلحة', Icons.layers_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(cycleCtrl, 'الطور الدراسي / القسم', Icons.school_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(dobCtrl, 'تاريخ الميلاد', Icons.cake_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(roomCtrl, 'رقم الغرفة (يحددها المدير)', Icons.bed_outlined),
                    const SizedBox(height: 12),
                    _buildDialogField(sinceCtrl, 'مقيم منذ (مثال: 2024-09-15)', Icons.calendar_month_outlined),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    shape: const StadiumBorder(),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء إدخال الحقول الأساسية: الاسم وكلمة المرور')),
                      );
                      return;
                    }
                    
                    final updatedProfile = Map<String, dynamic>.from(profile);
                    updatedProfile['fullNameAr'] = nameCtrl.text.trim();
                    updatedProfile['password'] = passCtrl.text.trim();
                    updatedProfile['role'] = selectedRole;
                    updatedProfile['registrationNumber'] = regCtrl.text.trim();
                    updatedProfile['levelAr'] = levelCtrl.text.trim();
                    updatedProfile['cycleAr'] = cycleCtrl.text.trim();
                    updatedProfile['dateOfBirth'] = dobCtrl.text.trim();
                    updatedProfile['roomNumber'] = roomCtrl.text.trim();
                    updatedProfile['residentSince'] = sinceCtrl.text.trim();

                    final key = regCtrl.text.trim().isNotEmpty ? regCtrl.text.trim() : username;
                    await FirebaseService().saveProfile(key, updatedProfile);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث بيانات الحساب بنجاح!')),
                      );
                    }
                  },
                  child: const Text('تحديث', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColor.primaryColor, size: 18),
        filled: true,
        fillColor: AppColor.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  String _getRoleLabel(String role) {
    return AppRoleX.fromString(role).labelAr;
  }

  Color _getRoleColor(String role) {
    return AppRoleX.fromString(role).color;
  }
}
