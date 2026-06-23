import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/driver_route_model.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
    });
  }

  Future<void> updateVehicleInfo(String userId, VehicleInfo vehicle) async {
    await _firestore.collection('users').doc(userId).update({
      'vehicle': vehicle.toMap(),
    });
  }

  Future<void> updateNTSAInfo(String userId, NTSAInfo ntsa) async {
    await _firestore.collection('users').doc(userId).update({
      'ntsa': ntsa.toMap(),
    });
  }

  Future<void> updateNTSAField(String userId, String field, dynamic value) async {
    await _firestore.collection('users').doc(userId).update({
      'ntsa.$field': value,
    });
  }

  Stream<QuerySnapshot> getAvailableRideRequests() {
    return _firestore
        .collection('rideRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> acceptRideRequest(String requestId, String driverId) async {
    await _firestore.collection('rideRequests').doc(requestId).update({
      'status': 'accepted',
      'driverId': driverId,
    });
  }

  Future<void> rejectRideRequest(String requestId, String driverId) async {
    await _firestore.collection('rideRequests').doc(requestId).update({
      'rejectedBy': FieldValue.arrayUnion([driverId]),
    });
  }

  Future<void> saveDriverRoute(DriverRoute route) async {
    await _firestore.collection('driverRoutes').doc(route.driverId).set(
      route.toMap(),
    );
  }

  Future<DriverRoute?> getDriverRoute(String driverId) async {
    final doc = await _firestore.collection('driverRoutes').doc(driverId).get();
    if (!doc.exists) return null;
    return DriverRoute.fromMap(doc.data()!);
  }

  Future<void> deactivateDriverRoute(String driverId) async {
    await _firestore.collection('driverRoutes').doc(driverId).update({
      'isActive': false,
    });
  }
}
