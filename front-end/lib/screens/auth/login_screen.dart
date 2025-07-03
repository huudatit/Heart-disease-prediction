// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/screens/auth/splash_screen.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingAutoLogin = true;
  String _language = 'en';

  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Health System',
      'checkingLogin': 'Checking login status...',
      'hintStaffId': 'Staff ID',
      'hintPassword': 'Password',
      'btnLogin': 'Log In',
      'enterStaffId': 'Please enter Staff ID',
      'enterPassword': 'Please enter password',
      'userNotFound': 'User not found',
      'invalidCredentials': 'Invalid ID or password',
      'hello': 'Welcome',
      'english': 'English',
      'vietnamese': 'Vietnamese',
    },
    'vi': {
      'appTitle': 'Hệ Thống Y Tế',
      'checkingLogin': 'Đang kiểm tra đăng nhập...',
      'hintStaffId': 'Mã nhân viên',
      'hintPassword': 'Mật khẩu',
      'btnLogin': 'Đăng Nhập',
      'enterStaffId': 'Vui lòng nhập mã nhân viên',
      'enterPassword': 'Vui lòng nhập mật khẩu',
      'userNotFound': 'Không tìm thấy tài khoản',
      'invalidCredentials': 'Mã hoặc mật khẩu không đúng',
      'hello': 'Xin chào',
      'english': 'English',
      'vietnamese': 'Tiếng Việt',
    },
  };

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
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
          if (!mounted) return;
          _navigateToHome(user);
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isCheckingAutoLogin = false);
  }

  void _navigateToHome(UserModel user) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
    // TODO: replace SplashScreen with appropriate home router
  }

  Future<void> _handleLogin() async {
    final labels = _labels[_language]!;
    final id = _staffIdController.text.trim();
    final pw = _passwordController.text;

    if (id.isEmpty) {
      return _showSnackBar(labels['enterStaffId']!, isError: true);
    }
    if (pw.isEmpty) {
      return _showSnackBar(labels['enterPassword']!, isError: true);
    }

    setState(() => _isLoading = true);
    try {
      final col = FirebaseFirestore.instance.collection('staffs');
      final snap = await col.where('staffId', isEqualTo: id).limit(1).get();
      if (snap.docs.isEmpty) {
        _showSnackBar(labels['userNotFound']!, isError: true);
      } else {
        final doc = snap.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        if (data['password'] != pw) {
          _showSnackBar(labels['invalidCredentials']!, isError: true);
        } else {
          final user = UserModel.fromDoc(doc);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('staffId', id);
          await prefs.setString('role', user.role.toString().split('.').last);
          if (!mounted) return;
          _navigateToHome(user);
          _showSnackBar('${labels['hello']} ${user.fullName}!', isError: false);
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[_language]!;
    if (_isCheckingAutoLogin) return _buildLoading();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          },
        ),
        title: Text(labels['appTitle']!, style: AppTextStyles.appBar),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Card(
              color: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginLarge),
                    Text(
                      labels['appTitle']!,
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.marginLarge),
                    TextField(
                      controller: _staffIdController,
                      decoration: AppInputStyles.standard(
                        hintText: labels['hintStaffId'],
                        prefixIcon: const Icon(
                          Icons.badge,
                          color: AppColors.primary,
                        ),
                      ),
                      style: AppTextStyles.bodyLarge,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: AppInputStyles.standard(
                        hintText: labels['hintPassword'],
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      style: AppTextStyles.bodyLarge,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: AppSizes.marginLarge),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: AppButtonStyles.primary,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                labels['btnLogin']!,
                                style: AppTextStyles.button,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labels[_language]!['checkingLogin']!,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSizes.marginMedium),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
