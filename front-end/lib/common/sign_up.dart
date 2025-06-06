import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers cho các TextField
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthYearController = TextEditingController();

  bool _isLoading = false;
  final _uuid = Uuid();
  String? _selectedGender;

  // 1. Biến lưu ngôn ngữ hiện tại (mặc định "en")
  String _language = 'en';

  // 2. Map chứa nhãn theo cả hai ngôn ngữ
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Sign Up',
      'hintName': 'Full Name',
      'hintEmail': 'Email',
      'hintPhone': 'Phone Number',
      'hintBirthYear': 'Birth Year',
      'gender': 'Gender:',
      'male': 'Male',
      'female': 'Female',
      'fillAllFields': 'Please fill in all fields',
      'phoneExists': 'Phone number already registered',
      'signUpSuccess': 'Sign up successful',
      'error': 'Error:',
      'btnSignUp': 'Sign Up',
    },
    'vi': {
      'appTitle': 'Đăng Ký Tài Khoản',
      'hintName': 'Họ và tên',
      'hintEmail': 'Email',
      'hintPhone': 'Số điện thoại',
      'hintBirthYear': 'Năm sinh',
      'gender': 'Giới tính:',
      'male': 'Nam',
      'female': 'Nữ',
      'fillAllFields': 'Vui lòng điền đầy đủ thông tin',
      'phoneExists': 'Số điện thoại đã được đăng ký',
      'signUpSuccess': 'Đăng ký thành công',
      'error': 'Lỗi:',
      'btnSignUp': 'Đăng Ký',
    },
  };

  /// 3. Xử lý khi bấm nút Sign Up
  void _handleSignUp() async {
    final labels = _labels[_language]!;

    // Kiểm tra xem đã điền đầy đủ chưa
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _birthYearController.text.isEmpty ||
        _selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(labels['fillAllFields']!)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();

      // Kiểm tra phone đã tồn tại trong Firestore chưa
      final phoneQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: phone)
              .get();

      if (phoneQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(labels['phoneExists']!)));
      } else {
        final userId = _uuid.v4();

        // Lưu user mới vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'name': name,
          'email': _emailController.text.trim(),
          'birthYear': int.parse(_birthYearController.text.trim()),
          'createdAt': FieldValue.serverTimestamp(),
          'phone': phone,
          'gender': _selectedGender,
          'role': 'user',
        });

        // Hiện thông báo thành công
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(labels['signUpSuccess']!)));

        // Quay về màn trước (thường là LoginScreen)
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Sign up error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${labels['error']} $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy map các nhãn tương ứng với ngôn ngữ hiện tại
    final labels = _labels[_language]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(labels['appTitle']!),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,

        // 4. PopupMenuButton để chuyển ngôn ngữ
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _language = value; // 'en' hoặc 'vi'
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(
                        color:
                            _language == 'en' ? Colors.blue[800] : Colors.black,
                        fontWeight:
                            _language == 'en'
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'vi',
                    child: Text(
                      'Tiếng Việt',
                      style: TextStyle(
                        color:
                            _language == 'vi' ? Colors.blue[800] : Colors.black,
                        fontWeight:
                            _language == 'vi'
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TextField cho Họ và tên
          _buildTextField(
            controller: _nameController,
            label: labels['hintName']!,
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),

          // TextField cho Email
          _buildTextField(
            controller: _emailController,
            label: labels['hintEmail']!,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // TextField cho Số điện thoại
          _buildTextField(
            controller: _phoneController,
            label: labels['hintPhone']!,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // TextField cho Năm sinh
          _buildTextField(
            controller: _birthYearController,
            label: labels['hintBirthYear']!,
            icon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Phần chọn giới tính
          Text(
            labels['gender']!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(labels['male']!),
                  value: labels['male']!,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(labels['female']!),
                  value: labels['female']!,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nút Đăng Ký
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : ElevatedButton(
                onPressed: _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  labels['btnSignUp']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// 5. Hàm xây dựng 1 TextField với style giống nhau
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 10, right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue[800], size: 24),
          ),
          hintStyle: TextStyle(color: Colors.blue[800], fontSize: 16),
          border: InputBorder.none,
        ),
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.blue[800], fontSize: 16),
      ),
    );
  }
}
