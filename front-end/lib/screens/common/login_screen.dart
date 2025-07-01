// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sign_up.dart';
import 'package:dacn_app/screens/common/splash_screen.dart';
import 'package:dacn_app/screens/common/home_screen.dart';
import 'package:dacn_app/screens/admin/admin_home_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/widgets/app_theme.dart'; // Import theme

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double? height;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppDimensions.buttonHeightLarge,
      child: ElevatedButton(
        style: AppButtons.primaryButtonStyle,
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(label, style: AppTextStyles.buttonLarge),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool isPatient;
  const LoginScreen({Key? key, required this.isPatient}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingAutoLogin = true;
  String _language = 'en';

  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Health System',
      'checkingLogin': 'Checking login status...',
      'hintIdentifier': 'Email or Phone',
      'hintPassword': 'Password',
      'btnLogin': 'Log In',
      'noAccount': "Don't have an account?",
      'signUp': 'Sign Up',
      'enterIdentifier': 'Please enter email or phone',
      'enterPassword': 'Please enter password',
      'userNotFound': 'User not found',
      'invalidCredentials': 'Invalid email/phone or password',
      'hello': 'Welcome',
      'english': 'English',
      'vietnamese': 'Vietnamese',
    },
    'vi': {
      'appTitle': 'Hệ Thống Y Tế',
      'checkingLogin': 'Đang kiểm tra đăng nhập...',
      'hintIdentifier': 'Email hoặc Số điện thoại',
      'hintPassword': 'Mật khẩu',
      'btnLogin': 'Đăng Nhập',
      'noAccount': 'Chưa có tài khoản?',
      'signUp': 'Đăng Ký',
      'enterIdentifier': 'Vui lòng nhập email hoặc số điện thoại',
      'enterPassword': 'Vui lòng nhập mật khẩu',
      'userNotFound': 'Không tìm thấy tài khoản',
      'invalidCredentials': 'Email/số điện thoại hoặc mật khẩu không đúng',
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone');
    final savedEmail = prefs.getString('email');
    final savedRole = prefs.getString('role');

    if (savedRole != null && (savedPhone != null || savedEmail != null)) {
      try {
        final col = FirebaseFirestore.instance.collection('users');
        QuerySnapshot snap;
        if (savedPhone != null) {
          snap = await col.where('phone', isEqualTo: savedPhone).limit(1).get();
        } else {
          snap = await col.where('email', isEqualTo: savedEmail).limit(1).get();
        }
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final user = UserModel.fromDoc(doc);
          if (!mounted) return;
          _navigateToHome(user);
          return;
        }
      } catch (_) {
        // ignore
      }
    }
    if (mounted) setState(() => _isCheckingAutoLogin = false);
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

  Future<void> _handleLogin() async {
    final labels = _labels[_language]!;
    final id = _identifierController.text.trim();
    final pw = _passwordController.text;

    if (id.isEmpty) {
      return _showSnackBar(
        widget.isPatient ? labels['enterIdentifier']! : 'Please enter Staff ID',
        isError: true,
      );
    }
    if (pw.isEmpty) {
      return _showSnackBar(labels['enterPassword']!, isError: true);
    }

    setState(() => _isLoading = true);

    try {
      // 1) Chọn đúng collection
      final col =
          widget.isPatient
              ? FirebaseFirestore.instance.collection('patients')
              : FirebaseFirestore.instance.collection('staffs');
      // 2) Chọn đúng field để lookup
      final field =
          widget.isPatient ? (id.contains('@') ? 'email' : 'phone') : 'staffId';

      // 3) Query duy nhất một lần
      final snap = await col.where(field, isEqualTo: id).limit(1).get();
      if (snap.docs.isEmpty) {
        _showSnackBar(labels['userNotFound']!, isError: true);
      } else {
        final doc = snap.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        if (data['password'] != pw) {
          _showSnackBar(labels['invalidCredentials']!, isError: true);
        } else {
          // DÙNG luôn fromDoc:
          final user = UserModel.fromDoc(doc);
          await _saveLoginInfo(id, user);
          if (!mounted) return;
          _navigateToHome(user);
          _showSnackBar('${labels['hello']} ${user.fullname}!', isError: false);
        }
      }

    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoginInfo(String id, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.isPatient) {
      // lưu email/phone cho patient
      if (id.contains('@')) {
        await prefs.setString('email', id);
        await prefs.remove('phone');
      } else {
        await prefs.setString('phone', id);
        await prefs.remove('email');
      }
    } else {
      // lưu staffId cho staff/admin/doctor/nurse
      await prefs.setString('staffId', id);
      await prefs.remove('phone');
      await prefs.remove('email');
    }
    // lưu role
    await prefs.setString('role', user.role.toString().split('.').last);
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
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[_language]!;
    final idHint = !widget.isPatient
        ? 'Staff ID'
        : labels['hintIdentifier']!;
    if (_isCheckingAutoLogin) return _buildLoadingScreen(labels);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(labels),
      body: _buildBody(labels),
    );
  }

  Widget _buildLoadingScreen(Map<String, String> labels) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels['checkingLogin']!, style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppDimensions.marginMedium),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, String> labels) {
    return AppBar(
      backgroundColor: AppColors.primary,
      // 1) Thêm nút back ở bên trái
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        },
      ),

      title: Text(labels['appTitle']!, style: AppTextStyles.appBarTitle),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.language, color: AppColors.white),
          onSelected: (v) => setState(() => _language = v),
          itemBuilder:
              (_) => [
                PopupMenuItem(value: 'en', child: Text(labels['english']!)),
                PopupMenuItem(value: 'vi', child: Text(labels['vietnamese']!)),
              ],
        ),
      ],
    );
  }


  Widget _buildBody(Map<String, String> labels) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: _buildLoginCard(labels),
        ),
      ),
    );
  }

  Widget _buildLoginCard(Map<String, String> labels) {
    // 1) Tính trước hintText, icon, keyboardType dựa trên isPatient/isStaff
    final idHint =
        widget.isPatient
            ? labels['hintIdentifier']! // “Email hoặc Số điện thoại”
            : 'Staff ID';
    final idIcon = widget.isPatient ? Icons.person_outline : Icons.badge;
    final idKeyboard =
        widget.isPatient ? TextInputType.emailAddress : TextInputType.text;

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(),
          const SizedBox(height: AppDimensions.marginLarge),
          Text(
            labels['appTitle']!,
            style: AppTextStyles.appTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.marginLarge),

          // 2) Ô nhập identifier dùng chung layout
          TextField(
            controller: _identifierController,
            decoration: AppInputDecorations.standard(
              hintText: idHint,
              prefixIcon: Icon(idIcon, color: AppColors.primary),
            ),
            style: AppTextStyles.bodyLarge,
            keyboardType: idKeyboard,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AppDimensions.marginMedium),

          // 3) Ô nhập mật khẩu như cũ
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: AppInputDecorations.standard(
              hintText: labels['hintPassword']!,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
            ),
            style: AppTextStyles.bodyLarge,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),

          const SizedBox(height: AppDimensions.marginLarge),
          PrimaryButton(
            label: labels['btnLogin']!,
            onPressed: _handleLogin,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.marginLarge),

          // 4) Chỉ show Sign Up nếu isPatient
          if (widget.isPatient)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(labels['noAccount']!, style: AppTextStyles.bodyMedium),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                  style: AppButtons.textButtonStyle,
                  child: Text(
                    labels['signUp']!,
                    style: AppTextStyles.linkNormal,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'logo',
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Image.asset(
            'assets/logo/logo.png',
            errorBuilder:
                (ctx, err, stack) => Container(
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.medical_services,
                    size: AppDimensions.iconXLarge,
                    color: AppColors.white,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
