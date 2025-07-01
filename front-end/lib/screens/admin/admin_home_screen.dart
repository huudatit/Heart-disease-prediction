// lib/screens/admin/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dacn_app/screens/common/splash_screen.dart';
import 'package:dacn_app/screens/admin/user_mangement_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/widgets/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Trang dashboard của admin, có thêm profile card lấy từ Firestore
class AdminHomeScreen extends StatefulWidget {
  final UserModel user;
  const AdminHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _language = 'en';
  final _labels = {
    'en': {
      'dashboard': 'Admin Dashboard',
      'logout': 'Log out',
      'english': 'English',
      'vietnamese': 'Vietnamese',
      'greeting': 'Hello',
    },
    'vi': {
      'dashboard': 'Bảng điều khiển Admin',
      'logout': 'Đăng xuất',
      'english': 'English',
      'vietnamese': 'Tiếng Việt',
      'greeting': 'Xin chào',
    },
  };
  late Future<UserModel> _adminFuture;

  @override
  void initState() {
    super.initState();
    // 1) Lấy thẳng UserModel từ Firestore
    _adminFuture = FirebaseFirestore.instance
        .collection('staffs')
        .doc(widget.user.uid)
        .get()
        .then((doc) {
          if (!doc.exists) throw 'Admin not found';
          return UserModel.fromDoc(doc);
        });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('phone');
    await prefs.remove('email');
    await prefs.remove('staffId');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

   @override
  Widget build(BuildContext ctx) {
    final t = _labels[_language]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t['dashboard']!, style: AppTextStyles.appBarTitle),
        centerTitle: true,
        actions: [
          // Nút chuyển ngôn ngữ
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.white),
            onSelected: (lang) => setState(() => _language = lang),
            itemBuilder:
                (_) => [
                  PopupMenuItem(value: 'en', child: Text(t['english']!)),
                  PopupMenuItem(value: 'vi', child: Text(t['vietnamese']!)),
                ],
          ),
          // Nút đăng xuất
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
          children: [
            // 2) FutureBuilder<UserModel> thay vì DocumentSnapshot
            FutureBuilder<UserModel>(
              future: _adminFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || !snap.hasData) {
                  return Text(
                    'Không tải được thông tin',
                    style: AppTextStyles.bodyLarge,
                  );
                }
                final admin = snap.data!;

                // 3) Dùng luôn admin.staffId, admin.department, admin.uid, admin.fullname ...
                return Card(
                  color: AppColors.cardBackground,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin Admin', style: AppTextStyles.h4),
                        const SizedBox(height: AppDimensions.marginSmall),
                        Text(
                          'Full Name: ${admin.fullname}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppDimensions.marginSmall),
                        Text(
                          'ID: ${admin.staffId}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        
                        if (admin.department != null) ...[
                          const SizedBox(height: AppDimensions.marginSmall),
                          Text(
                            'Phòng ban: ${admin.department}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            // Các chức năng
            Expanded(
              child: ListView(
                children: [
                  _buildFunctionCard(
                    icon: Icons.people,
                    label: 'Quản lý người dùng',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildFunctionCard(
                    icon: Icons.analytics,
                    label: 'Xem logs hệ thống',
                    onTap: () {
                      // TODO
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildFunctionCard(
                    icon: Icons.settings,
                    label: 'Cài đặt hệ thống',
                    onTap: () {
                      // TODO
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo Card chức năng reuse
  Widget _buildFunctionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      shadowColor: AppColors.shadowMedium,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: Icon(
          icon,
          size: AppDimensions.iconXLarge,
          color: AppColors.primary,
        ),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
