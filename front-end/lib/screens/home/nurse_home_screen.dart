import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/screens/nurse/nurse_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';

import 'package:dacn_app/screens/nurse/assessment_queue_screen.dart';
import 'package:dacn_app/screens/nurse/patient_monitoring_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trang Home dành cho Y tá (Nurse)
class NurseHomeScreen extends StatefulWidget {
  final String userName;
  final UserRole userRole;
  final String userId;
  final String language;

  const NurseHomeScreen({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.userId,
    this.language = 'en', required UserModel user,
  }) : super(key: key);

  @override
  _NurseHomeScreenState createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> {
  bool get isVI => widget.language == 'vi';

  @override
  void initState() {
    super.initState();
    // Kiểm tra đăng nhập sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final staffId = prefs.getString('staffId');
      if (staffId == null) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  void _showChangePasswordDialog() {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                        content: Text(
                          isVI
                              ? 'Mật khẩu không khớp'
                              : 'Passwords do not match',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.currentUser!.updatePassword(
                      newCtrl.text,
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isVI
                              ? 'Đổi mật khẩu thành công'
                              : 'Password changed successfully',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    // ignore: use_build_context_synchronously
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
          isVI ? 'Trang chủ Y tá' : 'Nurse Home',
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
            // Thông tin nurse
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
                          Text(
                            'ID: ${widget.userId}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.lock, color: AppColors.info),
                      onPressed: _showChangePasswordDialog,
                    ),        
                  ],
                ),
              ),
            ),
            // Menu
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
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => NurseDashboardScreen(),
                          ),
                        ),
                  ),
                  _buildCard(
                    icon: Icons.queue,
                    label: isVI ? 'Hàng đợi đánh giá' : 'Assessment Queue',
                    color: AppColors.warning,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const AssessmentQueueScreen(),
                          ),
                        ),
                  ),
                  _buildCard(
                    icon: Icons.monitor_heart,
                    label: isVI ? 'Giám sát BN' : 'Patient Monitoring',
                    color: AppColors.info,
                    onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PatientMonitoringScreen(),
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