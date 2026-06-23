import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_env.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: currentFirebaseOptions,
  );
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kUseProdFirebase
          ? const AndroidPlayIntegrityProvider()
          : AndroidDebugProvider(
              debugToken: kDebugMode
                  ? 'F1B0A5C2-D8E3-4F67-9C0A-1B2C3D4E5F60'
                  : null,
            ),
    );
  } catch (_) {
    // App Check not critical during development
  }
  runApp(const TaxiShaApp());
}

class TaxiShaApp extends StatelessWidget {
  const TaxiShaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxisha',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}