import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dacn_app/widgets/app_theme.dart';
import 'package:dacn_app/screens/common/splash_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/common/login_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final UserModel user;

  const PatientHomeScreen({Key? key, required this.user}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // Đăng xuất Firebase
    await FirebaseAuth.instance.signOut();
    // Xóa thông tin đăng nhập
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phone');
    await prefs.remove('email');
    await prefs.remove('role');
    // Điều hướng về LoginScreen, xóa toàn bộ stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ sơ sức khỏe của ${user.fullname}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('health_predictions')
                .where('patientId', isEqualTo: patientId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final dateStr =
                  ts != null
                      ? DateFormat('dd/MM/yyyy').format(ts.toDate())
                      : 'N/A';
              final pred = data['prediction'] as int? ?? 0;
              final status = pred == 1 ? 'Nguy cơ cao' : 'Nguy cơ thấp';

              return ListTile(
                leading: Icon(
                  pred == 1 ? Icons.warning_amber : Icons.check_circle,
                  color: pred == 1 ? Colors.red : Colors.green,
                ),
                title: Text(dateStr),
                subtitle: Text(status),
              );
            },
          );
        },
      ),
    );
  }
}
