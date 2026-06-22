enum UserRole { passenger, driver, admin }

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String verificationStatus; // pending, approved, rejected
  final double ratingAvg;
  final int ratingCount;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.verificationStatus = 'pending',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'verificationStatus': verificationStatus,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.passenger,
      ),
      verificationStatus: map['verificationStatus'] ?? 'pending',
      ratingAvg: (map['ratingAvg'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
    );
  }
}