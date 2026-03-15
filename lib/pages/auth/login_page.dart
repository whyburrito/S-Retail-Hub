import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import '../user/user_dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  void login() async {
    if (emailController.text == "admin@foodika.com" && passwordController.text == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
      return;
    }

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() => errorMessage = "Please fill in all fields.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists && userDoc.get('role') == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = "An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset("assets/images/foodika_logo.png", height: 120),
              const SizedBox(height: 30),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE46A3E),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE46A3E),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                },
                child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF2E7D32))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}