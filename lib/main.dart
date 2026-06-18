import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: currentFirebaseOptions,
  );
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxisha')),
      body: const Center(
        child: Text('Firebase connected ✅'),
      ),
    );
  }
}