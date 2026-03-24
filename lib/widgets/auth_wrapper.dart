import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/login_screen.dart';
import '../screens/main_nav_screen.dart';
import '../screens/profile_setup_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Mientras carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si está autenticado
        if (snapshot.hasData && snapshot.data != null) {
          // Verificar si tiene perfil configurado
          return FutureBuilder<bool>(
            future: FirestoreService.instance.hasUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final hasProfile = profileSnapshot.data ?? false;

              if (hasProfile) {
                return const MainNavScreen();
              } else {
                // Si no tiene perfil, ir a configuración
                return const ProfileSetupScreen();
              }
            },
          );
        }

        // Si no está autenticado
        return const LoginScreen();
      },
    );
  }
}

