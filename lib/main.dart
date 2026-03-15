import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import './pages/splash/splash_screen.dart';
import './providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(const FoodikaApp());
}

class FoodikaApp extends StatelessWidget {
  const FoodikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Foodika',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            secondary: const Color(0xFFFF8C00),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}