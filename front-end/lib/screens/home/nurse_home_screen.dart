// lib/screens/home/nurse_home_screen.dart

import 'package:flutter/material.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';

import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/screens/nurse/assessment_queue_screen.dart';
import 'package:dacn_app/screens/nurse/patient_monitoring_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trang chủ dành cho Y tá
class NurseHomeScreen extends StatelessWidget {
  final UserModel user;
  final String language;

  const NurseHomeScreen({Key? key, required this.user, this.language = 'en'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Trang chủ Y tá' : 'Nurse Home',
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
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tvi ? 'Xin chào, ${user.fullName}' : 'Welcome, ${user.fullName}',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSizes.marginLarge),
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
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AssessmentFormScreen(
                                  language: language,
                                  userRole: user.role,
                                ),
                          ),
                        ),
                  ),
                  _buildCard(
                    icon: Icons.queue,
                    label: tvi ? 'Hàng đợi đánh giá' : 'Assessment Queue',
                    color: AppColors.warning,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AssessmentQueueScreen(language: language),
                          ),
                        ),
                  ),
                  _buildCard(
                    icon: Icons.monitor_heart,
                    label: tvi ? 'Giám sát BN' : 'Patient Monitoring',
                    color: AppColors.info,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PatientMonitoringScreen(language: language),
                          ),
                        ),
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
