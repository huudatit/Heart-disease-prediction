// lib/screens/common/splash_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dacn_app/screens/auth/login_screen.dart';
import 'package:dacn_app/screens/home/home_router.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/config/theme_config.dart';

/// SplashScreen without role selection, auto-login if possible, else navigates to LoginScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  String _language = 'en';
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Health System',
      'checkingLogin': 'Checking login status...',
      'english': 'English',
      'vietnamese': 'Vietnamese',
    },
    'vi': {
      'appTitle': 'Hệ Thống Y Tế',
      'checkingLogin': 'Đang kiểm tra đăng nhập...',
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
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), _attemptAutoLogin);
  }

  Future<void> _attemptAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('staffId');
    final savedRole = prefs.getString('role');
    if (savedId != null && savedRole != null) {
      try {
        final col = FirebaseFirestore.instance.collection('staffs');
        final snap =
            await col.where('staffId', isEqualTo: savedId).limit(1).get();
        if (snap.docs.isNotEmpty) {
          final user = UserModel.fromDoc(snap.docs.first);
          _navigateToHome(user);
          return;
        }
      } catch (_) {}
    }
    // If auto-login fails, go to LoginScreen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToHome(UserModel user) {
    // Use HomeRouter to navigate based on role
    HomeRouter.toRole(
      context,
      user: user,
      language: _language,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[_language]!;
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
            const SizedBox(height: AppSizes.marginLarge),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: AppSizes.marginMedium),
            Text(labels['checkingLogin']!, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
