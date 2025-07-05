// lib/screens/home/home_router.dart
import 'package:flutter/material.dart';
import 'package:dacn_app/screens/home/admin_home_screen.dart';
import 'package:dacn_app/screens/home/doctor_home_screen.dart';
import 'package:dacn_app/screens/home/nurse_home_screen.dart';
import 'package:dacn_app/models/user_model.dart';

class HomeRouter {
  static Widget forRole({required UserModel user, String language = 'en'}) {
    switch (user.role) {
      case UserRole.admin:
        return AdminHomeScreen(user: user, language: language);

      case UserRole.doctor:
        return DoctorHomeScreen(
          user: user,
          language: language,
          userName: user.fullName,
          userRole: user.role,
          userId: user.uid,
        );

      case UserRole.nurse:
        return NurseHomeScreen(
          user: user,
          language: language,
          userName: user.fullName,
          userRole: user.role,
          userId: user.uid,
        );
    }
  }

  static void toRole(
    BuildContext context, {
    required UserModel user,
    String language = 'en',
  }) {
    final screen = forRole(user: user, language: language);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false, // Clear toàn bộ navigation stack
    );
  }
}