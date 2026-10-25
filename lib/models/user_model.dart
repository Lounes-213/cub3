class UserModel {
  final String username;
  final String password;
  final String fullNameAr;
  final String role;
  final String registrationNumber;
  final String levelAr;
  final String cycleAr;
  final bool isActive;
  final String? photo;
  final String? dateOfBirth;
  final String? roomNumber;
  final String? residentSince;

  UserModel({
    required this.username,
    required this.password,
    required this.fullNameAr,
    required this.role,
    required this.registrationNumber,
    required this.levelAr,
    required this.cycleAr,
    required this.isActive,
    this.photo,
    this.dateOfBirth,
    this.roomNumber,
    this.residentSince,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullNameAr: map['fullNameAr'] ?? '',
      role: map['role'] ?? 'etud',
      registrationNumber: map['registrationNumber'] ?? '',
      levelAr: map['levelAr'] ?? '',
      cycleAr: map['cycleAr'] ?? '',
      isActive: map['isActive'] ?? true,
      photo: map['photo'],
      dateOfBirth: map['dateOfBirth'],
      roomNumber: map['roomNumber'],
      residentSince: map['residentSince'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'fullNameAr': fullNameAr,
      'role': role,
      'registrationNumber': registrationNumber,
      'levelAr': levelAr,
      'cycleAr': cycleAr,
      'isActive': isActive,
      'photo': photo,
      'dateOfBirth': dateOfBirth,
      'roomNumber': roomNumber,
      'residentSince': residentSince,
    };
  }
}
