import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ride_request_model.dart';

class PassengerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<String> createRideRequest({
    required String passengerName,
    required String passengerPhone,
    required String pickup,
    required String destination,
    required double bidAmount,
    double pickupLat = 0.0,
    double pickupLng = 0.0,
    double destLat = 0.0,
    double destLng = 0.0,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');

    final docRef = _firestore.collection('rideRequests').doc();
    final request = RideRequest(
      id: docRef.id,
      passengerId: uid,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickup: pickup,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destination: destination,
      destLat: destLat,
      destLng: destLng,
      bidAmount: bidAmount,
    );
    await docRef.set(request.toMap());
    return docRef.id;
  }

  Stream<RideRequest?> activeRequestStream() {
    final uid = _userId;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('rideRequests')
        .where('passengerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final request = RideRequest.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data(),
          );
          return (request.status == 'pending' || request.status == 'accepted')
              ? request
              : null;
        });
  }

  Stream<List<RideRequest>> historyStream() {
    final uid = _userId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('rideRequests')
        .where('passengerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RideRequest.fromMap(
                    doc.id,
                    doc.data(),
                  ))
              .where((r) => r.status == 'completed' || r.status == 'cancelled')
              .toList();
        });
  }

  Future<void> cancelRideRequest(String requestId) async {
    await _firestore.collection('rideRequests').doc(requestId).update({
      'status': 'cancelled',
    });
  }
}
