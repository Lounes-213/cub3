import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/theme.dart';
import '../../services/firebase_service.dart';

class AdminTeamsScreen extends StatefulWidget {
  const AdminTeamsScreen({super.key});

  @override
  State<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends State<AdminTeamsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('إدارة رموز الفرق'),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _firebaseService.teamsStream,
        builder: (context, teamsSnapshot) {
          final teams = teamsSnapshot.data ?? {};
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, size: 80, color: Colors.white10),
                  const SizedBox(height: 24),
                  const Text('لم يتم توليد رموز الفرق بعد', style: TextStyle(color: AppColor.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _firebaseService.updateGameState(
                      status: 'active',
                      teamSize: 3, // Default values
                      numTeams: 4,
                    ),
                    child: const Text('توليد الرموز الآن'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColor.surfaceColor.withValues(alpha: 0.5),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColor.primaryColor, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'قم بتوزيع هذه الرموز على الفرق. يمكنهم مسحها للانضمام تلقائياً.',
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final sortedKeys = teams.keys.toList()..sort();
                    final slotId = sortedKeys[index];
                    final teamData = teams[slotId];
                    final isReg = teamData != null && teamData['is_registered'] == true;
                    final slotNum = int.tryParse(slotId.split('_').last) ?? (index + 1);
                    return _buildTeamCard(slotNum, isReg, teamData?['qr_code'] ?? '', teamData?['name']);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(int number, bool isRegistered, String qrData, String? teamName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isRegistered ? AppColor.correctColor : Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          if (isRegistered) BoxShadow(color: AppColor.correctColor.withValues(alpha: 0.1), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('فريق $number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          if (teamName != null && isRegistered) 
            Text(teamName, style: const TextStyle(fontSize: 10, color: AppColor.primaryColor)),
          const SizedBox(height: 12),
          if (qrData.isNotEmpty)
            GestureDetector(
              onTap: () => _showLargeQR(qrData, number),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(data: qrData, size: 100),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRegistered ? Icons.check_circle : Icons.pending,
                color: isRegistered ? AppColor.correctColor : Colors.white24,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isRegistered ? 'مسجل' : 'في الانتظار',
                style: TextStyle(
                  fontSize: 10,
                  color: isRegistered ? AppColor.correctColor : Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreActionBtn(Icons.remove, Colors.red, () {
                _firebaseService.updateTeamScore('team_$number', -1);
              }),
              const SizedBox(width: 16),
              _scoreActionBtn(Icons.add, Colors.green, () {
                _firebaseService.updateTeamScore('team_$number', 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showLargeQR(String data, int number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رمز الفريق $number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: QrImageView(data: data, size: 250),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
