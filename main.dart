import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'src/models/app_user.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_user_service.dart';
import 'src/services/outpass_service.dart';
import 'src/services/announcement_service.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/common/splash_screen.dart';
import 'src/screens/dashboards/admin_dashboard.dart';
import 'src/screens/dashboards/guard_dashboard.dart';
import 'src/screens/dashboards/student_dashboard.dart';
import 'src/screens/dashboards/warden_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HostelOutpassApp());
}

class HostelOutpassApp extends StatelessWidget {
  const HostelOutpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFFF8A00); // orange
    const brandDark = Color(0xFFF97316);
    const surface = Color(0xFFFFFBF6);
    const bg = Color(0xFFF7F7FB);

    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreUserService>(
          create: (_) => FirestoreUserService(),
        ),
        Provider<OutpassService>(
          create: (_) => OutpassService(),
        ),
        Provider<AnnouncementService>(
          create: (_) => AnnouncementService(),
        ),
        StreamProvider<AppUser?>(
          create: (context) =>
              context.read<AuthService>().authStateWithProfile(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'HostelOutpass',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: brand,
            brightness: Brightness.light,
            primary: brand,
            secondary: brandDark,
            surface: surface,
          ),
          scaffoldBackgroundColor: bg,
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: FontWeight.w800),
            titleLarge: TextStyle(fontWeight: FontWeight.w700),
            titleMedium: TextStyle(fontWeight: FontWeight.w700),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: brand,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 1.5,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE7E7EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: brand, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              side: const BorderSide(color: Color(0xFFE7E7EE)),
              foregroundColor: const Color(0xFF111827),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<AppUser?>(context);

    if (appUser == null) {
      return const LoginScreen();
    }

    if (!appUser.isProfileLoaded) {
      return const SplashScreen(message: 'Loading profile...');
    }

    switch (appUser.role) {
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.warden:
        return const WardenDashboard();
      case UserRole.guard:
        return const GuardDashboard();
      case UserRole.admin:
        return const AdminDashboard();
    }
  }
}

