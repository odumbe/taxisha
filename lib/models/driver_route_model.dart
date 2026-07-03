import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRoute {
  final String driverId;
  final String driverName;
  final String pickupArea;
  final double pickupLat;
  final double pickupLng;
  final String destinationArea;
  final double destLat;
  final double destLng;
  final double minBid;
  final double maxBid;
  final bool isActive;
  final DateTime updatedAt;

  DriverRoute({
    required this.driverId,
    this.driverName = '',
    this.pickupArea = '',
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.destinationArea = '',
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.minBid = 0,
    this.maxBid = 0,
    this.isActive = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'driverName': driverName,
    'pickupArea': pickupArea,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'destinationArea': destinationArea,
    'destLat': destLat,
    'destLng': destLng,
    'minBid': minBid,
    'maxBid': maxBid,
    'isActive': isActive,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory DriverRoute.fromMap(Map<String, dynamic> map) => DriverRoute(
    driverId: map['driverId'] ?? '',
    driverName: map['driverName'] ?? '',
    pickupArea: map['pickupArea'] ?? '',
    pickupLat: (map['pickupLat'] ?? 0.0).toDouble(),
    pickupLng: (map['pickupLng'] ?? 0.0).toDouble(),
    destinationArea: map['destinationArea'] ?? '',
    destLat: (map['destLat'] ?? 0.0).toDouble(),
    destLng: (map['destLng'] ?? 0.0).toDouble(),
    minBid: (map['minBid'] ?? 0).toDouble(),
    maxBid: (map['maxBid'] ?? 0).toDouble(),
    isActive: map['isActive'] ?? true,
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );
}
