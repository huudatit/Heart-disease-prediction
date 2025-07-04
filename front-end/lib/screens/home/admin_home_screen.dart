// lib/screens/home/admin_home_screen.dart
import 'package:flutter/material.dart';

import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/screens/home/home_router.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserModel user;
  final String language;

  const AdminHomeScreen({Key? key, required this.user, this.language = 'en'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: AppTextStyles.appBar),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user.fullName}', style: AppTextStyles.h2),
            const SizedBox(height: AppSizes.marginLarge),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: AppColors.primary,
              ),
              title: const Text(
                'User Management',
                style: AppTextStyles.bodyLarge,
              ),
              onTap: () {
                // TODO: Navigate to user management
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text(
                'System Settings',
                style: AppTextStyles.bodyLarge,
              ),
              onTap: () {
                // TODO: Navigate to settings
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HomeRouter.toRole(
            context,
            user: user,
            language: language,
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.logout),
      ),
    );
  }
}
