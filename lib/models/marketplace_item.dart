import 'package:flutter/material.dart';

/// غرض معروض في سوق الطلبة الداخلي (بيع أو إعارة أو تبادل).
/// بحد أقصى 3 أغراض معروضة لكل طالب.
class MarketplaceItem {
  final String id;
  final String matricule;
  final String sellerName;
  final String sellerPhone;
  final String pavilion;
  final String roomNumber;
  final String title;
  final String description;
  final double price;
  final bool isFree;
  final String category; // 'books', 'appliances', 'electronics', 'other'
  final List<String> images; // max 3 images
  final String status; // 'available', 'sold'
  final String createdAt;

  const MarketplaceItem({
    required this.id,
    required this.matricule,
    required this.sellerName,
    required this.sellerPhone,
    this.pavilion = '',
    this.roomNumber = '',
    required this.title,
    this.description = '',
    this.price = 0,
    this.isFree = false,
    this.category = 'books',
    this.images = const [],
    this.status = 'available',
    this.createdAt = '',
  });

  bool get isSold => status == 'sold';
  bool get hasImages => images.isNotEmpty;

  String get cleanPhone =>
      sellerPhone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

  String get formattedPrice {
    if (isFree || price == 0) {
      return 'مجاني / إعارة 🎁';
    }
    return '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} دج';
  }

  String get categoryLabelAr {
    switch (category) {
      case 'books':
        return 'كتب ومراجع 📚';
      case 'clothing':
        return 'ألبسة وملابس 👕';
      case 'appliances':
        return 'مستلزمات الغرف 🛏️';
      case 'electronics':
        return 'أجهزة وإلكترونيات 💻';
      default:
        return 'أغراض أخرى 📦';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'books':
        return Icons.menu_book;
      case 'clothing':
        return Icons.checkroom;
      case 'appliances':
        return Icons.kitchen;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'books':
        return Colors.blueAccent;
      case 'clothing':
        return Colors.pinkAccent;
      case 'appliances':
        return Colors.orangeAccent;
      case 'electronics':
        return Colors.purpleAccent;
      default:
        return Colors.tealAccent;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matricule': matricule,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'pavilion': pavilion,
        'roomNumber': roomNumber,
        'title': title,
        'description': description,
        'price': price,
        'isFree': isFree,
        'category': category,
        'images': images.take(3).toList(),
        'status': status,
        'createdAt': createdAt,
      };

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    }

    return MarketplaceItem(
      id: (json['id'] ?? '').toString(),
      matricule: (json['matricule'] ?? '').toString(),
      sellerName: (json['sellerName'] ?? 'طالب').toString(),
      sellerPhone: (json['sellerPhone'] ?? '').toString(),
      pavilion: (json['pavilion'] ?? '').toString(),
      roomNumber: (json['roomNumber'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isFree: json['isFree'] == true || json['isFree'] == 1,
      category: (json['category'] ?? 'books').toString(),
      images: parsedImages,
      status: (json['status'] ?? 'available').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  MarketplaceItem copyWith({
    String? id,
    String? matricule,
    String? sellerName,
    String? sellerPhone,
    String? pavilion,
    String? roomNumber,
    String? title,
    String? description,
    double? price,
    bool? isFree,
    String? category,
    List<String>? images,
    String? status,
    String? createdAt,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      pavilion: pavilion ?? this.pavilion,
      roomNumber: roomNumber ?? this.roomNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      category: category ?? this.category,
      images: images != null ? images.take(3).toList() : this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
