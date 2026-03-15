import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();
  final cityController = TextEditingController();

  String userStatus = 'Other';
  final List<String> statusOptions = ['Student', 'Professional', 'Business Owner', 'Other'];

  DateTime? selectedBirthday;
  String? imageUrlInput;
  String? existingImageUrl;
  bool isLoading = true;
  bool isSaving = false;
  bool hasCompletedProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (user != null) {
      // Pointing to the new capitalized 'Users' node
      var doc = await FirebaseFirestore.instance.collection('Users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          cityController.text = data['city'] ?? '';
          if (statusOptions.contains(data['userStatus'])) userStatus = data['userStatus'];
          if (data['birthday'] != null) selectedBirthday = (data['birthday'] as Timestamp).toDate();
          existingImageUrl = data['profileImageUrl'];
          hasCompletedProfile = data['hasCompletedProfile'] ?? false;
        });
      }
    }
    setState(() => isLoading = false);
  }

  void _saveDetails() async {
    setState(() => isSaving = true);

    try {
      String finalImageUrl = imageUrlInput ?? existingImageUrl ?? "";

      bool isNowComplete = nameController.text.isNotEmpty && selectedBirthday != null && userStatus != 'Other';
      int pointsToAdd = 0;

      if (isNowComplete && !hasCompletedProfile) {
        pointsToAdd = 50;
        hasCompletedProfile = true;
      }

      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).set({
        'name': nameController.text.trim(),
        'city': cityController.text.trim(),
        'userStatus': userStatus,
        'birthday': selectedBirthday != null ? Timestamp.fromDate(selectedBirthday!) : null,
        'profileImageUrl': finalImageUrl,
        'hasCompletedProfile': hasCompletedProfile,
        'points': FieldValue.increment(pointsToAdd),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(pointsToAdd > 0 ? "🎉 +50 Points Earned! Profile Updated." : "Profile updated successfully!"),
                backgroundColor: Colors.green
            )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uidSnippet = user?.uid.substring(0, 8).toUpperCase() ?? "00000000";

    return Scaffold(
      appBar: AppBar(title: const Text("Personal Details"), backgroundColor: const Color(0xFF002244), foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFFB8860B).withOpacity(0.2),
              backgroundImage: (imageUrlInput != null || existingImageUrl != null)
                  ? NetworkImage(imageUrlInput ?? existingImageUrl!)
                  : null,
              child: (imageUrlInput == null && existingImageUrl == null)
                  ? const Icon(Icons.person, size: 60, color: Color(0xFF002244))
                  : null,
            ),
            const SizedBox(height: 10),
            Text("UID: $uidSnippet", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            const Align(alignment: Alignment.centerLeft, child: Text("Basic Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF002244)))),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: "Neighborhood / City")),
            const SizedBox(height: 20),

            const Align(alignment: Alignment.centerLeft, child: Text("Personalize Your Experience", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF002244)))),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: userStatus,
              decoration: const InputDecoration(labelText: "User Status", helperText: "Helps us find deals relevant to you!"),
              items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => userStatus = val!),
            ),
            const SizedBox(height: 10),

            ListTile(
              title: Text(selectedBirthday == null ? "Select Birthday" : "Birthday: ${DateFormat('MMMM dd, yyyy').format(selectedBirthday!)}"),
              subtitle: const Text("Unlock special birthday rewards"),
              leading: const Icon(Icons.cake_outlined, color: Color(0xFFB8860B)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2005),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => selectedBirthday = picked);
              },
            ),
            const SizedBox(height: 30),

            if (!hasCompletedProfile)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(child: Text("Complete your status and birthday to earn +50 S-Retail Points! ⭐", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                  ],
                ),
              ),

            ElevatedButton(
              onPressed: isSaving ? null : _saveDetails,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8860B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}