import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneEmailController = TextEditingController();
  bool _isLoading = false;
  bool _useEmailLogin = false;
  bool _isCheckingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // Kiểm tra auto login khi mở app
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('phone');
      final savedEmail = prefs.getString('email');
      final savedRole = prefs.getString('userRole');

      if ((savedPhone != null || savedEmail != null) && savedRole != null) {
        // Có thông tin đăng nhập đã lưu, kiểm tra trong Firebase
        final query = FirebaseFirestore.instance.collection('users');
        final userSnapshot =
            await query
                .where(
                  savedPhone != null ? 'phone' : 'email',
                  isEqualTo: savedPhone ?? savedEmail,
                )
                .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first.data();
          final role = userData['role'] ?? 'user';

          // Điều hướng dựa trên role
          if (mounted) {
            if (role == 'admin') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(userData: userData),
                ),
              );
            }
            return;
          }
        }
      }
    } catch (e) {
      print('Error checking auto login: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingAutoLogin = false;
      });
    }
  }

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
    final input = _phoneEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập ${_useEmailLogin ? 'email' : 'số điện thoại'}',
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final query = FirebaseFirestore.instance.collection('users');
      final userSnapshot =
          await query
              .where(_useEmailLogin ? 'email' : 'phone', isEqualTo: input)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_useEmailLogin ? 'email' : 'phone', input);

        final role = userData['role'] ?? 'user';
        // Lưu role để kiểm tra khi reload app
        await prefs.setString('userRole', role);

        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xin chào ${userData['name']}!'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_useEmailLogin ? 'Email' : 'Số điện thoại'} chưa được đăng ký',
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading khi đang kiểm tra auto login
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F8FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
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
              CircularProgressIndicator(color: Colors.blue[800]),
              const SizedBox(height: 20),
              Text(
                'Đang kiểm tra thông tin đăng nhập...',
                style: TextStyle(color: Colors.blue[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

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
                  TextField(
                    controller: _phoneEmailController,
                    decoration: InputDecoration(
                      hintText: _useEmailLogin ? 'Email' : 'Số điện thoại',
                      prefixIcon: Icon(
                        _useEmailLogin ? Icons.email : Icons.phone,
                        color: Colors.blue[800],
                      ),
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
                    keyboardType:
                        _useEmailLogin
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useEmailLogin = !_useEmailLogin;
                      });
                    },
                    child: Text(
                      _useEmailLogin
                          ? 'Đăng nhập bằng số điện thoại'
                          : 'Đăng nhập bằng email',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
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
                                  'gender': 'Male',
                                  'role': 'user',
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
    _phoneEmailController.dispose();
    super.dispose();
  }
}
