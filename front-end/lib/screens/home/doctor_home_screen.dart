// lib/screens/home/doctor_home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/doctor/doctor_dasboard_screen.dart';
import 'package:dacn_app/models/user_model.dart';

/// Entry point for Doctor's home, delegates to the dashboard
class DoctorHomeScreen extends StatelessWidget {
  final UserModel user;
  final String language;

  const DoctorHomeScreen({
    Key? key,
    required this.user,
    this.language = 'en',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Trang chủ Bác sĩ' : 'Doctor Home',
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('staffId');
              await prefs.remove('role');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: DoctorDashboardScreen(
        userName: user.fullName,
        userRole: user.role,
        language: language,
      ),
    );
  }
}