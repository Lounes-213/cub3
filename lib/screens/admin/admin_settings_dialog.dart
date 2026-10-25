import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/firebase_service.dart';
import 'admin_qr_screen.dart';

class AdminSettingsDialog extends StatefulWidget {
  final Map<String, dynamic> gameData;
  const AdminSettingsDialog({super.key, required this.gameData});

  @override
  State<AdminSettingsDialog> createState() => _AdminSettingsDialogState();
}

class _AdminSettingsDialogState extends State<AdminSettingsDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late int _numTeams;
  late int _teamSize;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.gameData['title'] ?? '');
    _dateController = TextEditingController(text: widget.gameData['date'] ?? '');
    _numTeams = widget.gameData['num_teams'] ?? 4;
    _teamSize = widget.gameData['team_size'] ?? 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _firebaseService.updateGameSettings(
        title: _titleController.text.trim(),
        date: _dateController.text.trim(),
        numTeams: _numTeams,
        teamSize: _teamSize,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: AppColor.primaryColor.withValues(alpha: 0.2))),
      title: const Row(
        children: [
          Icon(Icons.settings, color: AppColor.primaryColor),
          SizedBox(width: 12),
          Text('إعدادات المسابقة', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('عنوان المسابقة', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
            const SizedBox(height: 8),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'مثلاً: دورة الربيع 2024')),
            const SizedBox(height: 20),
            const Text('التاريخ / المكان', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
            const SizedBox(height: 8),
            TextField(controller: _dateController, decoration: const InputDecoration(hintText: 'مثلاً: 15 ماي - قاعة المحاضرات')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCounter('عدد الفرق', _numTeams, (val) => setState(() => _numTeams = val)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCounter('أعضاء الفريق', _teamSize, (val) => setState(() => _teamSize = val)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('الحد: من 1 إلى 10 (فرق وأعضاء)',
                style: TextStyle(fontSize: 10.5, color: Colors.white38)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminQRScreen(numTeams: _numTeams))),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('استعراض وتوزيع أكواد الفرق'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppColor.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text('حذف المسابقة الحالية نهائياً', style: TextStyle(color: Colors.redAccent)),
                style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('حفظ التغييرات'),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged,
      {int max = 10}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove, size: 16), color: AppColor.primaryColor),
                Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add, size: 16), color: AppColor.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('تأكيد الحذف', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('هل أنت متأكد من أنك تريد حذف هذه المسابقة نهائياً؟ سيتم مسح جميع الفرق والنقاط ولن يمكنك التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: const StadiumBorder()),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation
              await _firebaseService.deleteActiveCompetition();
              if (!context.mounted) return;
              Navigator.pop(context); // Close settings
            },
            child: const Text('نعم، احذف المسابقة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
