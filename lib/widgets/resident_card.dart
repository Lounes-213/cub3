import 'package:flutter/material.dart';
import '../core/utils/photo_utils.dart';
import '../theme/theme.dart';

/// بطاقة المقيم الجامعي: الصورة، الاسم، رقم التسجيل، الغرفة، مقيم منذ.
/// تُعرض في مصلحة الإيواء (بيانات حقيقية من الحساب المتصل).
class ResidentCard extends StatelessWidget {
  final String fullNameAr;
  final String? photo;
  final String? registrationNumber;
  final String? roomNumber;
  final String? residentSince;
  final String? levelAr;

  const ResidentCard({
    super.key,
    required this.fullNameAr,
    this.photo,
    this.registrationNumber,
    this.roomNumber,
    this.residentSince,
    this.levelAr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final bytes = tryDecodePhoto(photo);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withValues(alpha: 0.22),
            AppColor.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColor.primaryColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.primaryColor, width: 2),
                ),
                child: ClipOval(
                  child: bytes != null
                      ? Image.memory(bytes,
                          width: 64, height: 64, fit: BoxFit.cover)
                      : Container(
                          width: 64,
                          height: 64,
                          color: Colors.white10,
                          child: const Icon(Icons.person,
                              size: 32, color: Colors.white38),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullNameAr.isEmpty ? '—' : fullNameAr,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registrationNumber?.isNotEmpty == true
                          ? 'رقم التسجيل: $registrationNumber'
                          : 'بطاقة مقيم',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (levelAr?.isNotEmpty == true)
                      Text(
                        levelAr!,
                        style: TextStyle(
                            color: textSecondary.withValues(alpha: 0.8),
                            fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _cell(
                  'رقم الغرفة',
                  roomNumber?.isNotEmpty == true
                      ? roomNumber!
                      : 'تُحدد من الإدارة',
                  AppColor.primaryColor,
                  textSecondary,
                ),
              ),
              Container(
                  width: 1, height: 36, color: textSecondary.withValues(alpha: 0.2)),
              Expanded(
                child: _cell(
                  'مقيم منذ',
                  residentSince?.isNotEmpty == true ? residentSince! : '—',
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontWeight: FontWeight.w900, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
