import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequest {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String pickup;
  final double pickupLat;
  final double pickupLng;
  final String destination;
  final double destLat;
  final double destLng;
  final double bidAmount;
  final String status;
  final List<String> rejectedBy;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.passengerId,
    this.passengerName = '',
    this.passengerPhone = '',
    required this.pickup,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    required this.destination,
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.bidAmount = 0,
    this.status = 'pending',
    this.rejectedBy = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'passengerId': passengerId,
    'passengerName': passengerName,
    'passengerPhone': passengerPhone,
    'pickup': pickup,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'destination': destination,
    'destLat': destLat,
    'destLng': destLng,
    'bidAmount': bidAmount,
    'status': status,
    'rejectedBy': rejectedBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory RideRequest.fromMap(String id, Map<String, dynamic> map) => RideRequest(
    id: id,
    passengerId: map['passengerId'] ?? '',
    passengerName: map['passengerName'] ?? '',
    passengerPhone: map['passengerPhone'] ?? '',
    pickup: map['pickup'] ?? '',
    pickupLat: (map['pickupLat'] ?? 0.0).toDouble(),
    pickupLng: (map['pickupLng'] ?? 0.0).toDouble(),
    destination: map['destination'] ?? '',
    destLat: (map['destLat'] ?? 0.0).toDouble(),
    destLng: (map['destLng'] ?? 0.0).toDouble(),
    bidAmount: (map['bidAmount'] ?? 0).toDouble(),
    status: map['status'] ?? 'pending',
    rejectedBy: List<String>.from(map['rejectedBy'] ?? []),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );
}
