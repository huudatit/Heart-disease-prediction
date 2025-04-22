import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _handleLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();

      // Tìm user theo số điện thoại
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: phone)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', phone);

        // Chuyển đến màn hình chính với thông tin người dùng
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xin chào ${userData['name']}!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại chưa được đăng ký')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đăng nhập: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo và Tiêu đề
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Hệ Thống Y Tế',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[800],
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Trường nhập số điện thoại
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone, color: Colors.blue[800]),
                      fillColor: Colors.blue[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.blue[800]!,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 25),

                  // Nút Đăng Nhập
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.blue[800])
                      : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Đăng Nhập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                  const SizedBox(height: 20),

                  // Liên kết Đăng Ký
                  TextButton(
                    onPressed: _navigateToSignUp,
                    child: Text(
                      'Chưa có tài khoản? Đăng ký ngay',
                      style: TextStyle(
                        color: Colors.blue[800],
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Nút Dùng Thử
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (_) => const HomeScreen(
                                userData: {
                                  'userId': 'test-user',
                                  'name': 'Người dùng thử',
                                  'email': 'test@example.com',
                                  'phone': '0123456789',
                                  'age': 25,
                                },
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'Dùng thử không cần đăng nhập',
                      style: TextStyle(
                        color: Colors.green[700],
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
