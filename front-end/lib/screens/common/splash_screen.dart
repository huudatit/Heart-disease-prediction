// lib/screens/common/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dacn_app/screens/common/home_screen.dart';
import 'package:dacn_app/screens/admin/admin_home_screen.dart';
import 'package:dacn_app/screens/common/login_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/widgets/app_theme.dart';

/// SplashScreen includes role selection before navigating to login
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  bool _showRoleSelection = false;

  String _language = 'en';
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Health System',
      'selectRole': 'Select Role',
      'patient': 'Patient',
      'staff': 'Staff',
      'english': 'English',
      'vietnamese': 'Vietnamese',
    },
    'vi': {
      'appTitle': 'Hệ Thống Y Tế',
      'selectRole': 'Chọn vai trò',
      'patient': 'Bệnh nhân',
      'staff': 'Nhân viên',
      'english': 'English',
      'vietnamese': 'Tiếng Việt',
    },
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = Tween(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), _attemptAutoLogin);
  }

  Future<void> _attemptAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final id = prefs.getString(role == 'patient' ? 'phone' : 'staffId');
    if (role != null && id != null) {
      try {
        final col =
            role == 'patient'
                ? FirebaseFirestore.instance.collection('users')
                : FirebaseFirestore.instance.collection('staff');
        final field = role == 'patient' ? 'phone' : 'staffId';
        final snap = await col.where(field, isEqualTo: id).limit(1).get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          // DÙNG luôn fromDoc cho tất cả staff/patient
          final user = UserModel.fromDoc(doc);
          _navigateToHome(user);
          return;
        }

      } catch (_) {}
    }
    if (mounted) setState(() => _showRoleSelection = true);
  }

  void _navigateToHome(UserModel user) {
    final route =
        user.role == UserRole.admin
            ? AdminHomeScreen(user: user)
            : HomeScreen(user: user);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => route),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRoleSelection) return _buildRoleSelection();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              _labels[_language]!['appTitle']!,
              style: AppTextStyles.appTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    final labels = _labels[_language]!;
    final buttonStyle = AppButtons.primaryButtonStyle.copyWith(
      minimumSize: MaterialStateProperty.all(
        Size(double.infinity, AppDimensions.buttonHeightLarge),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(labels['appTitle']!, style: AppTextStyles.appBarTitle),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.white),
            onSelected: (v) => setState(() => _language = v),
            itemBuilder:
                (_) => [
                  PopupMenuItem(value: 'en', child: Text(labels['english']!)),
                  PopupMenuItem(
                    value: 'vi',
                    child: Text(labels['vietnamese']!),
                  ),
                ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/logo.png', width: 100, height: 100),
                  const SizedBox(height: AppDimensions.marginLarge),
                  Text(labels['selectRole']!, style: AppTextStyles.h2),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => _goToLogin(isPatient: true),
                      child: Text(
                        labels['patient']!,
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => _goToLogin(isPatient: false),
                      child: Text(
                        labels['staff']!,
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin({required bool isPatient}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(isPatient: isPatient)),
    );
  }
}
