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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  void register() async {
    if (nameController.text.trim().isEmpty) {
      setState(() => errorMessage = "Please enter your full name.");
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

      await FirebaseFirestore.instance.collection('Users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'Consumer',
        'points': 50,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardPage()),
              (route) => false,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF002244)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 80, color: Color(0xFFB8860B)),
              const SizedBox(height: 20),
              const Text("BECOME A MEMBER", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF002244), letterSpacing: 1.5)),
              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder()),
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
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8860B)),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}