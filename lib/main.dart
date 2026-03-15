import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import './pages/splash/splash_screen.dart';
import './providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(const SRetailHubApp());
}

class SRetailHubApp extends StatelessWidget {
  const SRetailHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'S Retail Store',
        theme: ThemeData(
          // NEW AESTHETIC: Navy Blue and Gold
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF002244), // Deep Navy Blue
            primary: const Color(0xFF002244),
            secondary: const Color(0xFFB8860B), // Premium Gold
            surface: Colors.grey.shade50,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF002244),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002244),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}