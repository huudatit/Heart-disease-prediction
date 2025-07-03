// lib/screens/home/doctor/doctor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:dacn_app/config/theme_config.dart';

import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/screens/doctor/clinical_insights_screen.dart';
import 'package:dacn_app/screens/doctor/patient_reports_screen.dart';

import 'package:dacn_app/models/user_model.dart';

/// Dashboard dành cho Bác sĩ
class DoctorDashboardScreen extends StatelessWidget {
  final String userName;
  final UserRole userRole;
  final String language;

  const DoctorDashboardScreen({
    Key? key,
    required this.userName,
    required this.userRole,
    this.language = 'en',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Bảng điều khiển' : 'Dashboard',
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tvi ? 'Xin chào, $userName' : 'Welcome, $userName',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSizes.marginLarge),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.marginMedium,
              mainAxisSpacing: AppSizes.marginMedium,
              childAspectRatio: 1.2,
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
                              (_) => AssessmentFormScreen(
                                language: language,
                                userRole: userRole,
                              ),
                        ),
                      ),
                ),
                _buildCard(
                  icon: Icons.analytics,
                  label: tvi ? 'Báo cáo phân tích' : 'Reports',
                  color: AppColors.info,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientReportsScreen(),
                        ),
                      ),
                ),
                _buildCard(
                  icon: Icons.info_outline,
                  label: tvi ? 'Thông tin lâm sàng' : 'Insights',
                  color: AppColors.success,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClinicalInsightsScreen(),
                        ),
                      ),
                ),
                _buildCard(
                  icon: Icons.history,
                  label: tvi ? 'Lịch sử đánh giá' : 'History',
                  color: AppColors.warning,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientReportsScreen(),
                        ),
                      ),
                ),
              ],
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
