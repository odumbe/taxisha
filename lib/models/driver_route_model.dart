import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRoute {
  final String driverId;
  final String driverName;
  final String pickupArea;
  final String destinationArea;
  final double minBid;
  final double maxBid;
  final bool isActive;
  final DateTime updatedAt;

  DriverRoute({
    required this.driverId,
    this.driverName = '',
    this.pickupArea = '',
    this.destinationArea = '',
    this.minBid = 0,
    this.maxBid = 0,
    this.isActive = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'driverName': driverName,
    'pickupArea': pickupArea,
    'destinationArea': destinationArea,
    'minBid': minBid,
    'maxBid': maxBid,
    'isActive': isActive,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory DriverRoute.fromMap(Map<String, dynamic> map) => DriverRoute(
    driverId: map['driverId'] ?? '',
    driverName: map['driverName'] ?? '',
    pickupArea: map['pickupArea'] ?? '',
    destinationArea: map['destinationArea'] ?? '',
    minBid: (map['minBid'] ?? 0).toDouble(),
    maxBid: (map['maxBid'] ?? 0).toDouble(),
    isActive: map['isActive'] ?? true,
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );
}
