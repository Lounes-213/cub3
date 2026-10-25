import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        // Parse: musabaqat://join?gameId=USTHB_CUBE3&teamSlot=X
        final uri = Uri.tryParse(code);
        if (uri != null && uri.scheme == 'musabaqat' && uri.authority == 'join') {
          final slotStr = uri.queryParameters['teamSlot'];
          final int? slot = int.tryParse(slotStr ?? '');
          
          if (slot != null) {
            setState(() => _isScanned = true);
            Navigator.pop(context, slot);
            return;
          }
        }
        
        // Fallback: If code is just a number
        final int? directSlot = int.tryParse(code);
        if (directSlot != null && directSlot > 0 && directSlot <= 50) {
          setState(() => _isScanned = true);
          Navigator.pop(context, directSlot);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'مسح رمز الفريق',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () => _controller.toggleTorch(),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Scanning Frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primaryColor, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Corner markings or scan line animation can go here
                    ],
                  ),
                ),
                
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'وجه الكاميرا نحو رمز QR المخصص لفريقك',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'سيتم توجيهك تلقائياً لصفحة إكمال البيانات',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
