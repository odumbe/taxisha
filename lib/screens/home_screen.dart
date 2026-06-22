import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import 'passenger/passenger_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return FutureBuilder<AppUser?>(
          future: AuthService().getCurrentAppUser(),
          builder: (context, snapshot) {
            final appUser = snapshot.data;
            switch (appUser?.role) {
              case UserRole.passenger:
                return const PassengerHome();
              case UserRole.driver:
                return const Center(child: Text('Driver dashboard coming soon'));
              case UserRole.admin:
                return const Center(child: Text('Admin dashboard coming soon'));
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }
}
