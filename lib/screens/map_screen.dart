import 'dart:async';
// map screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../widgets/image_viewer_dialog.dart';
import '../providers/app_config_provider.dart';
import '../providers/user_provider.dart';
import '../core/auth/app_roles.dart';
import 'admin/admin_facilities_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;

  // Bab Ezzouar 3 Coordinates (Centered)
  final LatLng _initialCenter = const LatLng(36.722341, 3.187430);

  // Residence Facilities (from OSM notes)
  final List<MapFacility> _facilities = [
    // Pavilions
    MapFacility('جناح A', const LatLng(36.723046, 3.186738), Icons.business, 'pavilion'),
    MapFacility('جناح B', const LatLng(36.723252, 3.187162), Icons.business, 'pavilion'),
    MapFacility('جناح C', const LatLng(36.722887, 3.187403), Icons.business, 'pavilion'),
    MapFacility('جناح D', const LatLng(36.723106, 3.187827), Icons.business, 'pavilion', dedication: 'إهداء للعزيز D36 🌹'),
    MapFacility('جناح E', const LatLng(36.722345, 3.187269), Icons.business, 'pavilion', dedication: 'إهداء لـ E23.. الأسرار والأنوار ✨'),
    MapFacility('جناح F', const LatLng(36.722564, 3.187687), Icons.business, 'pavilion', dedication: 'إهداء لـ ناس F47 و F51 ❤️'),
    MapFacility('جناح G', const LatLng(36.722753, 3.188106), Icons.business, 'pavilion', dedication: 'إهداء للزعيم G36 👑'),
    MapFacility('جناح H', const LatLng(36.721993, 3.187510), Icons.business, 'pavilion'),
    MapFacility('جناح I', const LatLng(36.722212, 3.187940), Icons.business, 'pavilion'),
    MapFacility('جناح J', const LatLng(36.721404, 3.187666), Icons.business, 'pavilion'),
    MapFacility('جناح K', const LatLng(36.721597, 3.188100), Icons.business, 'pavilion'),
    MapFacility('جناح L', const LatLng(36.721803, 3.188524), Icons.business, 'pavilion'),
    MapFacility('جناح M', const LatLng(36.723067, 3.188674), Icons.business, 'pavilion'),
    MapFacility('جناح N', const LatLng(36.723519, 3.188390), Icons.business, 'pavilion'),
    
    // Services
    MapFacility('مطعم الإقامة', const LatLng(36.722203, 3.186051), Icons.restaurant, 'service'),
    MapFacility('وجبات سريعة', const LatLng(36.722366, 3.186089), Icons.fastfood, 'service'),
    MapFacility('مصلى الاعتصام', const LatLng(36.722461, 3.187167), Icons.mosque, 'service'),
    MapFacility('المتجر', const LatLng(36.722801, 3.186228), Icons.shopping_cart, 'service'),
    MapFacility('المرشات', const LatLng(36.722620, 3.186185), Icons.shower, 'service'),
    MapFacility('ملعب الإقامة', const LatLng(36.722912, 3.188932), Icons.sports_soccer, 'service'),
    MapFacility('ملعب رملي', const LatLng(36.722375, 3.188723), Icons.sports_volleyball, 'service'),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _centerOnUser() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 18);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد موقعك. تأكد من تفعيل GPS')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>().config;
    final canProgram = context.watch<UserProvider>().appRole.canProgramApp;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 17,
                maxZoom: 19,
                minZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.musabaqat_cube3',
                ),
                MarkerLayer(
                  markers: [
                    // User Location Marker
                    if (_currentPosition != null)
                      Marker(
                        point: _currentPosition!,
                        width: 40,
                        height: 40,
                        rotate: true,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 24),
                          ),
                        ),
                      ),
                    
                    // Facility Markers with media indicators
                    ..._facilities.map((facility) {
                      final data = config.getFacility(
                        facility.name,
                        defaultType: facility.type,
                        defaultDedication: facility.dedication,
                      );
                      final hasImages = data.hasImages;

                      return Marker(
                        point: facility.location,
                        width: 68,
                        height: 68,
                        rotate: true,
                        child: GestureDetector(
                          onTap: () => _showFacilityInfo(facility),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: facility.type == 'pavilion' 
                                          ? AppColor.primaryColor.withValues(alpha: 0.95)
                                          : AppColor.accentColor.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4)
                                      ],
                                    ),
                                    child: Icon(facility.icon, color: Colors.black, size: 17),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: hasImages
                                        ? AppColor.primaryColor.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  facility.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            
            // Top Floating Buttons (Back + Admin Option)
            Positioned(
              top: 16,
              right: 16,
              left: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMapActionBtn(Icons.arrow_back, () => Navigator.pop(context)),
                  if (canProgram)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)
                        ],
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16, color: AppColor.primaryColor),
                        label: const Text('إدارة المرافق',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminFacilitiesScreen()),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Action Buttons
            Positioned(
              bottom: 30,
              right: 20,
              child: Column(
                children: [
                  _buildMapActionBtn(Icons.my_location, _centerOnUser),
                  const SizedBox(height: 12),
                  _buildMapActionBtn(Icons.home, () => _mapController.move(_initialCenter, 17)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)
          ],
        ),
        child: Icon(icon, color: AppColor.primaryColor),
      ),
    );
  }

  // عرض تفاصيل الجناح أو المرفق مع الصور ورقم الهاتف والإهداء
  void _showFacilityInfo(MapFacility facility) {
    final appConfigProvider = context.read<AppConfigProvider>();
    final canProgram = context.read<UserProvider>().appRole.canProgramApp;
    final facilityData = appConfigProvider.config.getFacility(
      facility.name,
      defaultType: facility.type,
      defaultDedication: facility.dedication,
    );

    final isPavilion = facility.type == 'pavilion';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // الرأس: الاسم والنوع والرمز وزر الإدارة السريع إن وُجد
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isPavilion ? AppColor.primaryColor : AppColor.accentColor)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isPavilion ? AppColor.primaryColor : AppColor.accentColor)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      facility.icon,
                      color: isPavilion ? AppColor.primaryColor : AppColor.accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facilityData.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isPavilion ? 'إقامة طلبة (Pavillon)' : 'مرفق خدمي بالحي الجامعي',
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (canProgram)
                    IconButton(
                      icon: const Icon(Icons.settings, color: AppColor.primaryColor),
                      tooltip: 'برمجة الصور ورقم الهاتف',
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminFacilitiesScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // معرض الصور (مع التكبير وعارض الصور)
              if (facilityData.hasImages) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library, size: 16, color: AppColor.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'صور ${isPavilion ? "الجناح" : "المرفق"} (${facilityData.images.length}/3)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'انقر للتكبير 🔍',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: facilityData.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final imgUrl = facilityData.images[index];
                      return GestureDetector(
                        onTap: () => ImageViewerDialog.show(
                          context,
                          images: facilityData.images,
                          initialIndex: index,
                          title: facilityData.name,
                        ),
                        child: Hero(
                          tag: 'facility_img_${facilityData.name}_$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.network(
                                  imgUrl,
                                  width: 190,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, prog) {
                                    if (prog == null) return child;
                                    return Container(
                                      width: 190,
                                      height: 140,
                                      color: Colors.white10,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, _, _) => Container(
                                    width: 190,
                                    height: 140,
                                    color: Colors.white10,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white38),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // بطاقة رقم هاتف رئيس الجناح / مسؤول المرفق
              if (facilityData.hasChiefPhone) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.15),
                        AppColor.surfaceColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_in_talk, color: Colors.greenAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facilityData.chiefName.isNotEmpty
                                  ? facilityData.chiefName
                                  : (isPavilion ? 'رئيس الجناح (Chef de pavillon)' : 'مسؤول المرفق'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              facilityData.chiefPhone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                      // زر النسخ
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                        tooltip: 'نسخ الرقم',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: facilityData.chiefPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ رقم رئيس الجناح 📋'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      // زر الاتصال المباشر
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('اتصال'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          launchUrl(
                            Uri.parse('tel:${facilityData.cleanPhone}'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // الإهداء إن وُجد
              if (facilityData.dedication.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    facilityData.dedication,
                    style: const TextStyle(
                      color: AppColor.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ملاحظات إضافية إن وُجدت
              if (facilityData.notes.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          facilityData.notes,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // زر الإغلاق
              Center(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 42),
                      elevation: 4,
                    ),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    child: const Text('حسناً', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
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

class MapFacility {
  final String name;
  final LatLng location;
  final IconData icon;
  final String type; // pavilion or service
  final String? dedication;

  MapFacility(this.name, this.location, this.icon, this.type, {this.dedication});
}
