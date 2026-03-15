import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/user_dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController(); // NEW: Capture name early
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  void register() async {
    if (nameController.text.trim().isEmpty) {
      setState(() => errorMessage = "Please enter your name.");
      return;
    }
    if (passwordController.text != confirmController.text) {
      setState(() => errorMessage = "Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Initialize the user document with loyalty and tracking fields
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'user',
        'points': 0, // NEW: Initial points
        'hasCompletedProfile': false, // NEW: Tracks if they earned the bonus
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardPage()),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? "An error occurred.");
    } catch (e) {
      setState(() => errorMessage = "Database Error: ${e.toString()}");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/foodika_logo.png", width: 120),
              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}