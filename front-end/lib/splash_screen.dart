import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Tạo animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Tạo scale animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Bắt đầu animation
    _animationController.forward();

    // Kiểm tra trạng thái đăng nhập sau khi animation chạy
    Future.delayed(const Duration(milliseconds: 2000), () {
      _checkLoginStatus();
    });
  }

  // Phương thức kiểm tra trạng thái đăng nhập
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone');

    print('SavedPhone from SharedPreferences: $savedPhone'); // Debug

    if (savedPhone != null) {
      try {
        print('Querying Firestore for phone: $savedPhone'); // Debug

        final QuerySnapshot userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: savedPhone)
                .get();

        print('Query returned ${userSnapshot.docs.length} documents'); // Debug

        if (userSnapshot.docs.isNotEmpty) {
          final raw = userSnapshot.docs.first.data();
          final Map<String, dynamic> userData =
              raw is Map<String, dynamic> ? raw : <String, dynamic>{};

          print(
            'Found user data: ${userData['name']}, role=${userData['role']}',
          ); // Debug

          final String roleFromFirestore =
              (userData['role'] as String?) ?? 'user';

          if (mounted) {
            if (roleFromFirestore == 'admin') {
              // Nếu là admin → vào AdminDashboard
              print('Navigating to AdminDashboard');
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const AdminDashboard(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
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
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            } else {
              // Nếu là user bình thường → vào HomeScreen
              print('Navigating to HomeScreen as user');
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          HomeScreen(userData: userData),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
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
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            }
          }
          return; // Đã điều hướng xong, bỏ qua phần xuống login
        } else {
          print('No user found with phone: $savedPhone'); // Debug
        }
      } catch (e) {
        print('Error checking login status: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
        }
      }
    } else {
      print('No saved phone found in SharedPreferences'); // Debug
    }

    // Nếu chưa có login hoặc không tìm thấy user, chuyển về LoginScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const LoginScreen(),
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
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Soft blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo với animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 250,
                  height: 250,
                ),
              ),
            ),

            // Hiệu ứng loading
            const SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            ),

            // Dòng chữ dưới logo
            const SizedBox(height: 30),
            Text(
              'Hệ Thống Y Tế',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Giải phóng animation controller
    _animationController.dispose();
    super.dispose();
  }
}
