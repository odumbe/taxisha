import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import 'passenger/passenger_home.dart';
import 'driver/driver_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _retryTrigger = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return FutureBuilder<AppUser?>(
          key: ValueKey('profile_$_retryTrigger'),
          future: AuthService().getCurrentAppUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Failed to load profile',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => setState(() => _retryTrigger++),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final appUser = snapshot.data;
            if (appUser == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('User profile not found',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
            }
            switch (appUser.role) {
              case UserRole.passenger:
                return const PassengerHome();
              case UserRole.driver:
                return DriverHome(appUser: appUser);
              case UserRole.admin:
                return const Center(child: Text('Admin dashboard coming soon'));
            }
          },
        );
      },
    );
  }
}
