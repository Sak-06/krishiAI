import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'complete_profile_screen.dart';
import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class AuthRedirector {
  static Future<void> redirect(BuildContext context,
      {bool isGoogleSignIn = false,
        String? googleName,
        String? googlePhoto}) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // 🔹 NEW USER OR PROFILE NOT COMPLETE
    if (!doc.exists || doc.data()?['isProfileComplete'] != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            isGoogleSignIn: isGoogleSignIn,
            googleName: googleName,
            googleProfilePicture: googlePhoto,
          ),
        ),
      );
      return;
    }

    // 🔹 EXISTING USER
    final role = doc.data()!['role'];

    if (role == 'farmer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FarmerDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerDashboard()),
      );
    }
  }
}
