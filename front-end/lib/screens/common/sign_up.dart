import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/common/home_screen.dart';
import 'package:dacn_app/widgets/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _birthYearController = TextEditingController();
  

  final _uuid = Uuid();
  String? _selectedGender;
  bool _isLoading = false;

  String _language = 'en';
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Sign Up',
      'hintName': 'Full Name',
      'hintEmail': 'Email',
      'hintPassword': 'Password',
      'hintRePassword': 'Re-enter Password',
      'hintPhone': 'Phone Number',
      'hintBirthYear': 'Birth Year',
      'gender': 'Gender:',
      'male': 'Male',
      'female': 'Female',
      'fillAllFields': 'Please fill in all fields',
      'phoneExists': 'Phone number already registered',
      'signUpSuccess': 'Sign up successful',
      'error': 'Error:',
      'checkPassword': 'Passwords do not match',
      'invalidBirthYear': 'Invalid birth year',
      'btnSignUp': 'Sign Up',
    },
    'vi': {
      'appTitle': 'Đăng Ký Tài Khoản',
      'hintName': 'Họ và tên',
      'hintEmail': 'Email',
      'hintPassword': 'Mật khẩu',
      'hintRePassword': 'Nhập lại mật khẩu',
      'hintPhone': 'Số điện thoại',
      'hintBirthYear': 'Năm sinh',
      'gender': 'Giới tính:',
      'male': 'Nam',
      'female': 'Nữ',
      'fillAllFields': 'Vui lòng điền đầy đủ thông tin',
      'phoneExists': 'Số điện thoại đã được đăng ký',
      'signUpSuccess': 'Đăng ký thành công',
      'error': 'Lỗi:',
      'checkPassword': 'Mật khẩu không khớp',
      'invalidBirthYear': 'Năm sinh không hợp lệ',
      'btnSignUp': 'Đăng Ký',
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _selectedGender = null;
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final labels = _labels[_language] ?? _labels['en']!;
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _rePasswordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _birthYearController.text.isEmpty ||
        _selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(labels['fillAllFields']!)));
      return;
    }

    if (_passwordController.text != _rePasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(labels['checkPassword']!)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final birthYear = int.tryParse(_birthYearController.text.trim());
      if (birthYear == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(labels['invalidBirthYear']!)));
        return;
      }

      final phoneQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();
      if (phoneQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(labels['phoneExists']!)));
      } else {
        final userId = _uuid.v4();
        final newUser = UserModel(
          uid: userId,
          fullname: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: phone,
          role: UserRole.patient,
          department: null,
        );
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          ...newUser.toMap(),
          'password': _passwordController.text.trim(),
          'birthYear': birthYear,
          'gender': _selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', phone);
        await prefs.setString('role', 'patient');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(user: newUser)),
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(labels['signUpSuccess']!)));
      }
    } catch (e) {
      print('Error during signup: $e'); // Log lỗi để debug
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${labels['error']} $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[_language]!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(labels['appTitle']!, style: AppTextStyles.appBarTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: AppColors.white),
            onSelected: (v) => setState(() => _language = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  const PopupMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: ListView(
          children: [
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _nameController,
              label: labels['hintName']!,
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _emailController,
              label: labels['hintEmail']!,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _phoneController,
              label: labels['hintPhone']!,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _passwordController,
              label: labels['hintPassword']!,
              icon: Icons.lock_outline,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
            ),

            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _rePasswordController,
              label: labels['hintRePassword']!,
              icon: Icons.lock_outline,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
            ),

            const SizedBox(height: AppDimensions.paddingMedium),
            _buildTextField(
              backgroundColor: AppColors.cardBackground,
              controller: _birthYearController,
              label: labels['hintBirthYear']!,
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(labels['gender']!, style: AppTextStyles.bodyMedium),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      labels['male']!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    value: labels['male']!,
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(
                      labels['female']!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    value: labels['female']!,
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
                : ElevatedButton(
                  onPressed: _handleSignUp,
                  style: AppButtons.primaryButtonStyle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingXSmall,
                    ),
                    child: Text(
                      labels['btnSignUp']!,
                      style: AppTextStyles.buttonLarge,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

   Widget _buildTextField({
    required Color backgroundColor,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    bool obscureText = false,
  }) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: AppShadows.light,
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            hintText: label,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSmall),
              child: Icon(icon, color: AppColors.primary),
            ),
            border: InputBorder.none,
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
      );
}