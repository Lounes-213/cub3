import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/theme.dart';

class AdminQRScreen extends StatelessWidget {
  final int numTeams;
  const AdminQRScreen({super.key, required this.numTeams});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('أكواد الدخول (QR Codes)'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        itemCount: numTeams,
        itemBuilder: (context, index) {
          final teamId = index + 1;
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: AppColor.surfaceColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('الفريق $teamId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColor.primaryColor)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: QrImageView(
                            data: 'musabaqat://join?gameId=USTHB_CUBE3&teamSlot=$teamId',
                            version: QrVersions.auto,
                            size: 250.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.primaryColor, foregroundColor: Colors.black),
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Card(
              color: AppColor.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColor.primaryColor.withValues(alpha: 0.2))),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('الفريق $teamId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColor.primaryColor)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: QrImageView(
                          data: 'musabaqat://join?gameId=USTHB_CUBE3&teamSlot=$teamId',
                          version: QrVersions.auto,
                          size: 100.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('اضغط للتكبير', style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
