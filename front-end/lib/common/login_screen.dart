import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';
import '../user/home_screen.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneEmailController = TextEditingController();
  bool _isLoading = false;
  bool _useEmailLogin = false; // nếu true → nhập email; false → nhập phone
  bool _isCheckingAutoLogin =
      true; // để hiển thị màn loading khi kiểm tra SharedPreferences

  // 1. Biến lưu ngôn ngữ hiện tại (mặc định "en")
  String _language = 'en';

  // 2. Map chứa tất cả các nhãn theo 2 ngôn ngữ
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appTitle': 'Health System',
      'checkingLogin': 'Checking login status...',
      'hintPhone': 'Phone Number',
      'hintEmail': 'Email',
      'loginByEmail': 'Login with Phone',
      'loginByPhone': 'Login with Email',
      'btnLogin': 'Log In',
      'noAccount': 'Don\'t have an account? Sign up',
      'tryGuest': 'Try without login',
      'enterPhone': 'Please enter phone number',
      'enterEmail': 'Please enter email',
      'userNotFound': 'Not registered',
      'hello': 'Welcome',
      'logout': 'Logout',
    },
    'vi': {
      'appTitle': 'Hệ Thống Y Tế',
      'checkingLogin': 'Đang kiểm tra thông tin đăng nhập...',
      'hintPhone': 'Số điện thoại',
      'hintEmail': 'Email',
      'loginByEmail': 'Đăng nhập bằng số điện thoại',
      'loginByPhone': 'Đăng nhập bằng email',
      'btnLogin': 'Đăng Nhập',
      'noAccount': 'Chưa có tài khoản? Đăng ký ngay',
      'tryGuest': 'Dùng thử không cần đăng nhập',
      'enterPhone': 'Vui lòng nhập số điện thoại',
      'enterEmail': 'Vui lòng nhập email',
      'userNotFound': 'Chưa được đăng ký',
      'hello': 'Xin chào',
      'logout': 'Đăng xuất',
    },
  };

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  /// 3. Kiểm tra SharedPreferences + Firestore để tự động login
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('phone');
      final savedEmail = prefs.getString('email');
      final savedRole = prefs.getString('role'); // chúng ta chỉ đọc key "role"

      // Nếu đã từng lưu role và ít nhất có phone hoặc email, ta gọi Firestore để xác thực lại role thực tế
      if (savedRole != null && (savedPhone != null || savedEmail != null)) {
        QuerySnapshot userSnapshot;
        if (savedPhone != null) {
          userSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('phone', isEqualTo: savedPhone)
                  .get();
        } else {
          userSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: savedEmail)
                  .get();
        }

        if (userSnapshot.docs.isNotEmpty) {
          final raw = userSnapshot.docs.first.data();
          final Map<String, dynamic> userData =
              raw is Map<String, dynamic> ? raw : <String, dynamic>{};

          final String roleFromFirestore =
              (userData['role'] as String?) ?? 'user';

          // Nếu đang hiển thị và trang này vẫn mount, chuyển hướng
          if (mounted) {
            if (roleFromFirestore == 'admin') {
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
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking auto login: $e');
    }

    // Nếu không đủ điều kiện auto-login, chuyển về màn login thật
    if (mounted) {
      setState(() {
        _isCheckingAutoLogin = false;
      });
    }
  }

  /// 4. Chuyển đến màn đăng ký
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

  /// 5. Xử lý nút Login khi người dùng bấm
  Future<void> _handleLogin() async {
    final input = _phoneEmailController.text.trim();
    final labels = _labels[_language]!;

    // Nếu đang yêu cầu nhập phone nhưng rỗng, show lỗi
    if (!_useEmailLogin && input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(labels['enterPhone']!),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }
    // Nếu đang yêu cầu nhập email nhưng rỗng, show lỗi
    if (_useEmailLogin && input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(labels['enterEmail']!),
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

      final labels2 = _labels[_language]!;

      if (userSnapshot.docs.isNotEmpty) {
        // Ép kiểu document.data() thành Map<String, dynamic>
        final raw = userSnapshot.docs.first.data();
        final Map<String, dynamic> userData =
            raw is Map<String, dynamic> ? raw : <String, dynamic>{};

        // Lấy role thực sự (đọc từ Firestore field "role")
        final String role = (userData['role'] as String?) ?? 'user';

        // Lưu phone/email + role vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (_useEmailLogin) {
          await prefs.setString('email', input);
          await prefs.remove('phone');
        } else {
          await prefs.setString('phone', input);
          await prefs.remove('email');
        }
        await prefs.setString('role', role); // LUÔN LUÔN LƯU key "role"

        // Chuyển hướng
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
            content: Text('${labels2['hello']} ${userData['name']}!'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        // Nếu không tìm thấy user tương ứng
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(labels2['userNotFound']!),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      // Nếu có lỗi kết nối
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng nhập: $e'),
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
    final labels = _labels[_language]!;

    // 6. Nếu đang ở chế độ auto-login (kiểm tra SharedPreferences), hiển thị loading
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
                labels['appTitle']!,
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
                labels['checkingLogin']!,
                style: TextStyle(color: Colors.blue[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // 7. Khi không còn auto-login nữa, hiển thị hẳn màn login
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(labels['appTitle']!),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        actions: [
          // 8. PopupMenuButton cho chuyển ngôn ngữ
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
                    labels['appTitle']!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[800],
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 9. TextField cho Phone / Email
                  TextField(
                    controller: _phoneEmailController,
                    decoration: InputDecoration(
                      hintText:
                          _useEmailLogin
                              ? labels['hintEmail']!
                              : labels['hintPhone']!,
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

                  // 10. TextButton để chuyển đổi nhập phone / email
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useEmailLogin = !_useEmailLogin;
                      });
                    },
                    child: Text(
                      _useEmailLogin
                          ? labels['loginByEmail']!
                          : labels['loginByPhone']!,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 11. Nút Login
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
                        child: Text(
                          labels['btnLogin']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),

                  // 12. Link “Chưa có tài khoản? Đăng ký ngay”
                  TextButton(
                    onPressed: _navigateToSignUp,
                    child: Text(
                      labels['noAccount']!,
                      style: TextStyle(
                        color: Colors.blue[800],
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 13. Link “Dùng thử không cần đăng nhập”
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
                      labels['tryGuest']!,
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
