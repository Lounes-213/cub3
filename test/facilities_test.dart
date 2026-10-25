import 'package:flutter_test/flutter_test.dart';
import 'package:cube_iii/models/facility_data.dart';
import 'package:cube_iii/providers/app_config_provider.dart';

void main() {
  group('FacilityData & AppConfig tests', () {
    test('FacilityData model serialization, limit and getters', () {
      final f = FacilityData(
        id: 'جناح A',
        name: 'جناح A',
        type: 'pavilion',
        images: ['https://r2.test/img1.jpg', 'https://r2.test/img2.jpg'],
        chiefPhone: '0550 12 34 56',
        chiefName: 'أ. كمال',
        dedication: 'إهداء للجميع 🌹',
      );

      expect(f.isPavilion, isTrue);
      expect(f.hasChiefPhone, isTrue);
      expect(f.hasImages, isTrue);
      expect(f.cleanPhone, '0550123456');

      final map = f.toMap();
      final fromMap = FacilityData.fromMap(map);

      expect(fromMap.id, 'جناح A');
      expect(fromMap.name, 'جناح A');
      expect(fromMap.images.length, 2);
      expect(fromMap.chiefPhone, '0550 12 34 56');
      expect(fromMap.chiefName, 'أ. كمال');

      // Test 3 images max cap in copyWith
      final updated = f.copyWith(
        images: [
          'https://r2.test/1.jpg',
          'https://r2.test/2.jpg',
          'https://r2.test/3.jpg',
          'https://r2.test/4.jpg',
        ],
      );
      expect(updated.images.length, 3);
    });

    test('AppConfig stores and retrieves facilities properly', () {
      final config = AppConfig(
        facilitiesData: {
          'جناح B': FacilityData(
            id: 'جناح B',
            name: 'جناح B',
            type: 'pavilion',
            images: ['https://r2.test/pav_b.jpg'],
            chiefPhone: '0661998877',
          ),
        },
      );

      final retrieved = config.getFacility('جناح B');
      expect(retrieved.chiefPhone, '0661998877');
      expect(retrieved.images.length, 1);

      // Default fallback for unconfigured facility
      final unconfigured = config.getFacility(
        'جناح D',
        defaultType: 'pavilion',
        defaultDedication: 'إهداء للعزيز D36 🌹',
      );
      expect(unconfigured.dedication, 'إهداء للعزيز D36 🌹');
      expect(unconfigured.hasImages, isFalse);
      expect(unconfigured.hasChiefPhone, isFalse);

      final exported = config.toMap();
      final reloaded = AppConfig.fromMap(exported);
      expect(reloaded.facilitiesData.containsKey('جناح B'), isTrue);
      expect(reloaded.facilitiesData['جناح B']!.chiefPhone, '0661998877');
    });
  });
}
