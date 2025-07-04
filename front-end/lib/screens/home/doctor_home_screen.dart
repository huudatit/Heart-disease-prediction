// lib/screens/home/doctor_home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/doctor/doctor_dasboard_screen.dart';
import 'package:dacn_app/models/user_model.dart';

/// Entry point for Doctor's home, delegates to the dashboard
class DoctorHomeScreen extends StatefulWidget {
  final UserModel user;
  final String initialLanguage;

  const DoctorHomeScreen({
    super.key,
    required this.user,
    this.initialLanguage = 'en', required String language,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  void _onLanguageSelected(String lang) {
    if (lang == _language) return;
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tvi = _language == 'vi';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Trang chủ Bác sĩ' : 'Doctor Home',
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
        actions: [
          // 1) nút chọn ngôn ngữ
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.white),
            tooltip: tvi ? 'Chọn ngôn ngữ' : 'Select Language',
            onSelected: _onLanguageSelected,
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: _language == 'en' ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'vi',
                    child: Text(
                      'Vietnamese',
                      style: TextStyle(
                        color: _language == 'vi' ? AppColors.primary : null,
                      ),
                    ),
                  ),
                ],
          ),

          // 2) nút logout
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('staffId');
              await prefs.remove('role');
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: DoctorDashboardScreen(
        userName: widget.user.fullName,
        userId: widget.user.uid,
        userRole: widget.user.role,
        language: _language,
      ),
    );
  }
}
