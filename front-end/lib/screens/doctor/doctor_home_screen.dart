// lib/screens/doctor/doctor_home_screen.dart
import 'package:dacn_app/screens/user/input_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/common/splash_screen.dart';
import 'package:dacn_app/widgets/app_theme.dart';
import 'package:dacn_app/widgets/form_entry_button.dart';
import 'package:dacn_app/widgets/history_card.dart';
import 'package:dacn_app/widgets/algorithm_card.dart';

class DoctorHomeScreen extends StatefulWidget {
  final UserModel user;
  const DoctorHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _language = 'en';
  late Map<String, Map<String, String>> _labels;

  @override
  void initState() {
    super.initState();
    _labels = {
      'en': {
        'title': 'Doctor Dashboard',
        'logout': 'Log out',
        'english': 'English',
        'vietnamese': 'Vietnamese',
        'newDiagnosis': 'New Diagnosis',
        'history': 'History',
        'explain': 'Explain Model',
      },
      'vi': {
        'title': 'Bác sĩ: ${widget.user.fullname}',
        'logout': 'Đăng xuất',
        'english': 'Tiếng Anh',
        'vietnamese': 'Tiếng Việt',
        'newDiagnosis': 'Chẩn đoán mới',
        'history': 'Lịch sử',
        'explain': 'Giải thích mô hình',
      },
    };
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('staffId');
    await prefs.remove('phone');
    await prefs.remove('email');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _labels[_language]!;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('${t['title']}', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        actions: [
          // Language switcher
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.white),
            onSelected: (lang) => setState(() => _language = lang),
            itemBuilder:
                (_) => [
                  PopupMenuItem(value: 'en', child: Text(t['english']!)),
                  PopupMenuItem(value: 'vi', child: Text(t['vietnamese']!)),
                ],
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            tooltip: t['logout'],
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Card(
              color: AppColors.cardBackground,
              elevation: 2,
              shadowColor: AppColors.shadowMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.user.fullname}',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppDimensions.marginSmall),
                    Text(
                      'ID: ${widget.user.staffId}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppDimensions.marginSmall),
                    if (widget.user.department != null)
                      Text(
                        'Department: ${widget.user.department!}',
                        style: AppTextStyles.bodyMedium,
                      ),                   
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            // Action buttons
            FormEntryButton(
              icon: Icons.medical_services,
              label: t['newDiagnosis']!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InputFormScreen(
                      language: _language,
                      userRole: UserRole.doctor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
