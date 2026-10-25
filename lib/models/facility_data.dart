class FacilityData {
  final String id;
  final String name;
  final String type; // 'pavilion' | 'service'
  final List<String> images; // max 3 images
  final String chiefPhone;
  final String chiefName;
  final String dedication;
  final String notes;

  const FacilityData({
    required this.id,
    required this.name,
    this.type = 'pavilion',
    this.images = const [],
    this.chiefPhone = '',
    this.chiefName = '',
    this.dedication = '',
    this.notes = '',
  });

  bool get isPavilion => type == 'pavilion';
  bool get hasChiefPhone => chiefPhone.trim().isNotEmpty;
  bool get hasImages => images.isNotEmpty;

  /// Clean phone for tel: url_launcher scheme
  String get cleanPhone =>
      chiefPhone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'images': images,
        'chiefPhone': chiefPhone,
        'chiefName': chiefName,
        'dedication': dedication,
        'notes': notes,
      };

  factory FacilityData.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];
    if (map['images'] is List) {
      parsedImages = (map['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    }

    return FacilityData(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'pavilion').toString(),
      images: parsedImages,
      chiefPhone: (map['chiefPhone'] ?? '').toString(),
      chiefName: (map['chiefName'] ?? '').toString(),
      dedication: (map['dedication'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
    );
  }

  FacilityData copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? images,
    String? chiefPhone,
    String? chiefName,
    String? dedication,
    String? notes,
  }) {
    return FacilityData(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      images: images != null
          ? images.take(3).toList()
          : this.images,
      chiefPhone: chiefPhone ?? this.chiefPhone,
      chiefName: chiefName ?? this.chiefName,
      dedication: dedication ?? this.dedication,
      notes: notes ?? this.notes,
    );
  }
}
