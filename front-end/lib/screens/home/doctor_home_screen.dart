// lib/screens/home/doctor_home_screen.dart


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/screens/doctor/doctor_dasboard_screen.dart';
import 'package:dacn_app/screens/doctor/patient_reports_screen.dart';
import 'package:dacn_app/screens/doctor/clinical_insights_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trang Home dành cho Bác sĩ (Doctor)
class DoctorHomeScreen extends StatefulWidget {
  final String userName;
  final UserRole userRole;
  final String userId;
  final String language;

  const DoctorHomeScreen({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
    this.language = 'en', required UserModel user,
  }) : super(key: key);

  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool get isVI => widget.language == 'vi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final staffId = prefs.getString('staffId');
      if (staffId == null) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  void _showChangePassword() {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(isVI ? 'Đổi mật khẩu' : 'Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: isVI ? 'Mật khẩu mới' : 'New Password',
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: isVI ? 'Xác nhận mật khẩu' : 'Confirm Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isVI ? 'Hủy' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isVI ? 'Mật khẩu không khớp' : 'Passwords do not match'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.currentUser!.updatePassword(newCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isVI ? 'Đổi mật khẩu thành công' : 'Password changed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(isVI ? 'Lưu' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isVI ? 'Trang chủ Bác sĩ' : 'Doctor Home',
          style: AppTextStyles.appBar,
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [  
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
            // Thông tin bác sĩ
            Card(
              color: AppColors.cardBackground,
              margin: const EdgeInsets.only(bottom: AppSizes.marginLarge),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: AppColors.primary,
                      size: AppSizes.iconLarge,
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text('ID: ${widget.userId}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.lock, color: AppColors.info),
                      onPressed: _showChangePassword,
                    ),
                  ],
                ),
              ),
            ),
            // Menu chức năng
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.marginMedium,
                mainAxisSpacing: AppSizes.marginMedium,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                    icon: Icons.dashboard,
                    label: isVI ? 'Bảng điều khiển' : 'Dashboard',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorDashboardScreen(
                          userName: widget.userName,
                          userId: widget.userId,
                          language: widget.language,
                          userRole: widget.userRole,
                        ),
                      ),
                    ),
                  ),
                  _buildCard(
                    icon: Icons.receipt_long,
                    label: isVI ? 'Báo cáo BN' : 'Patient Reports',
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientReportsScreen(language: widget.language),
                      ),
                    ),
                  ),
                  _buildCard(
                    icon: Icons.insights,
                    label: isVI ? 'Phân tích lâm sàng' : 'Clinical Insights',
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClinicalInsightsScreen(language: widget.language),
                      ),
                    ),
                  ),
                  _buildCard(
                    icon: Icons.bar_chart,
                    label: isVI ? 'Thống kê' : 'Statistics',
                    color: AppColors.warning,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isVI ? 'Đang phát triển' : 'Coming soon'))),
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
            Text(label, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
