enum UserRole { passenger, driver, admin }

class VehicleInfo {
  final String make;
  final String model;
  final String color;
  final String plateNumber;
  final int year;
  final int seats;

  VehicleInfo({
    this.make = '',
    this.model = '',
    this.color = '',
    this.plateNumber = '',
    this.year = 0,
    this.seats = 4,
  });

  Map<String, dynamic> toMap() => {
    'make': make,
    'model': model,
    'color': color,
    'plateNumber': plateNumber,
    'year': year,
    'seats': seats,
  };

  factory VehicleInfo.fromMap(Map<String, dynamic> map) => VehicleInfo(
    make: map['make'] ?? '',
    model: map['model'] ?? '',
    color: map['color'] ?? '',
    plateNumber: map['plateNumber'] ?? '',
    year: map['year'] ?? 0,
    seats: map['seats'] ?? 4,
  );
}

class NTSAInfo {
  final String licenseNumber;
  final String licensePhoto;
  final bool licenseVerified;
  final String vehicleRegNumber;
  final String logBookPhoto;
  final bool vehicleRegVerified;
  final String psvBadgeNumber;
  final String psvBadgePhoto;
  final bool psvBadgeVerified;
  final String insuranceUrl;
  final bool insuranceVerified;
  final String verificationStatus;

  NTSAInfo({
    this.licenseNumber = '',
    this.licensePhoto = '',
    this.licenseVerified = false,
    this.vehicleRegNumber = '',
    this.logBookPhoto = '',
    this.vehicleRegVerified = false,
    this.psvBadgeNumber = '',
    this.psvBadgePhoto = '',
    this.psvBadgeVerified = false,
    this.insuranceUrl = '',
    this.insuranceVerified = false,
    this.verificationStatus = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'licenseNumber': licenseNumber,
    'licensePhoto': licensePhoto,
    'licenseVerified': licenseVerified,
    'vehicleRegNumber': vehicleRegNumber,
    'logBookPhoto': logBookPhoto,
    'vehicleRegVerified': vehicleRegVerified,
    'psvBadgeNumber': psvBadgeNumber,
    'psvBadgePhoto': psvBadgePhoto,
    'psvBadgeVerified': psvBadgeVerified,
    'insuranceUrl': insuranceUrl,
    'insuranceVerified': insuranceVerified,
    'verificationStatus': verificationStatus,
  };

  factory NTSAInfo.fromMap(Map<String, dynamic> map) => NTSAInfo(
    licenseNumber: map['licenseNumber'] ?? '',
    licensePhoto: map['licensePhoto'] ?? '',
    licenseVerified: map['licenseVerified'] ?? false,
    vehicleRegNumber: map['vehicleRegNumber'] ?? '',
    logBookPhoto: map['logBookPhoto'] ?? '',
    vehicleRegVerified: map['vehicleRegVerified'] ?? false,
    psvBadgeNumber: map['psvBadgeNumber'] ?? '',
    psvBadgePhoto: map['psvBadgePhoto'] ?? '',
    psvBadgeVerified: map['psvBadgeVerified'] ?? false,
    insuranceUrl: map['insuranceUrl'] ?? '',
    insuranceVerified: map['insuranceVerified'] ?? false,
    verificationStatus: map['verificationStatus'] ?? 'pending',
  );
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final String verificationStatus;
  final double ratingAvg;
  final int ratingCount;
  final bool isOnline;
  final VehicleInfo vehicle;
  final NTSAInfo ntsa;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.verificationStatus = 'pending',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.isOnline = false,
    VehicleInfo? vehicle,
    NTSAInfo? ntsa,
  }) : vehicle = vehicle ?? VehicleInfo(),
       ntsa = ntsa ?? NTSAInfo();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'verificationStatus': verificationStatus,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'isOnline': isOnline,
      'vehicle': vehicle.toMap(),
      'ntsa': ntsa.toMap(),
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
      isOnline: map['isOnline'] ?? false,
      vehicle: map['vehicle'] != null
          ? VehicleInfo.fromMap(Map<String, dynamic>.from(map['vehicle']))
          : VehicleInfo(),
      ntsa: map['ntsa'] != null
          ? NTSAInfo.fromMap(Map<String, dynamic>.from(map['ntsa']))
          : NTSAInfo(),
    );
  }
}
