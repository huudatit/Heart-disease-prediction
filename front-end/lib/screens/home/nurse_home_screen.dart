// lib/screens/home/nurse_home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';

import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/screens/nurse/assessment_queue_screen.dart';
import 'package:dacn_app/screens/nurse/patient_monitoring_screen.dart';

/// Trang chủ dành cho Y tá
class NurseHomeScreen extends StatefulWidget {
  final UserModel user;
  final String initialLanguage;

  const NurseHomeScreen({
    super.key,
    required this.user,
    this.initialLanguage = 'en', required String language,
  });

  @override
  // ignore: library_private_types_in_public_api
  _NurseHomeScreenState createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> {
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
          tvi ? 'Trang chủ Y tá' : 'Nurse Home',
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
        actions: [
          // nút chọn ngôn ngữ
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
                      'Tiếng Việt',
                      style: TextStyle(
                        color: _language == 'vi' ? AppColors.primary : null,
                      ),
                    ),
                  ),
                ],
          ),

          // nút logout
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

      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tvi
                  ? 'Xin chào, ${widget.user.fullName}'
                  : 'Welcome, ${widget.user.fullName}',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSizes.marginLarge),

            // phóng rộng để grid scroll nếu cần
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.marginMedium,
                mainAxisSpacing: AppSizes.marginMedium,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                    icon: Icons.add_chart,
                    label: tvi ? 'Đánh giá mới' : 'New Assessment',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AssessmentFormScreen(
                                language: _language,
                                userRole: widget.user.role,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: Icons.queue,
                    label: tvi ? 'Hàng đợi đánh giá' : 'Assessment Queue',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AssessmentQueueScreen(language: _language),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: Icons.monitor_heart,
                    label: tvi ? 'Giám sát BN' : 'Patient Monitoring',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  PatientMonitoringScreen(language: _language),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: Icons.bar_chart,
                    label: tvi ? 'Thống kê' : 'Statistics',
                    color: AppColors.success,
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tvi ? 'Đang phát triển' : 'Coming soon',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSizes.marginSmall),
            Text(
              label,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
