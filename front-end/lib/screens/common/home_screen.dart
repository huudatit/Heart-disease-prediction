// lib/screens/common/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/admin/admin_home_screen.dart';
import 'package:dacn_app/screens/doctor/doctor_home_screen.dart';
import 'package:dacn_app/screens/nurse/nurse_home_screen.dart';
import 'package:dacn_app/screens/patients/patient_home_screen.dart';

/// Màn hình chung dispatch theo role của user
class HomeScreen extends StatelessWidget {
  final UserModel user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return AdminHomeScreen(user: user);
      case UserRole.doctor:
        return DoctorHomeScreen(user: user);
      case UserRole.nurse:
        return NurseHomeScreen(user: user);
      case UserRole.patient:
        return PatientHomeScreen(user: user);
    }
  }
}
