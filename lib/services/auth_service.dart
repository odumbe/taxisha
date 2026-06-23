import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../firebase_env.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user, create their Firestore profile, and send email verification.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final uid = user.uid;

    final appUser = AppUser(
      id: uid,
      name: name,
      phone: phone,
      email: email,
      role: role,
      verificationStatus: role == UserRole.driver ? 'pending' : 'approved',
    );

    await _firestore.collection('users').doc(uid).set(appUser.toMap());
    await user.sendEmailVerification();

    return appUser;
  }

  /// Log in an existing user.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Fetch the full profile document for the current user.
  Future<AppUser?> getCurrentAppUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset({required String email}) async {
    final projectId = kUseProdFirebase ? 'taxisha-prod' : 'taxisha-staging';
    await _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://$projectId.firebaseapp.com/login',
        handleCodeInApp: true,
        androidPackageName: 'com.example.taxisha',
        iOSBundleId: 'com.example.taxisha',
      ),
    );
  }
}