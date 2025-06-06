import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_detail_screen.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalUsers = 0;
  int _maleUsers = 0;
  int _femaleUsers = 0;

  // Mặc định dùng tiếng Việt. Nếu bấm chọn "English", thì set 'en'.
  String _language = 'vi';

  @override
  void initState() {
    super.initState();
    _calculateUserStats();
  }

  void _calculateUserStats() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((
      snapshot,
    ) {
      if (mounted) {
        setState(() {
          _totalUsers = snapshot.docs.length;
          _maleUsers =
              snapshot.docs
                  .where(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['gender'] ==
                            'Male' ||
                        (doc.data() as Map<String, dynamic>)['gender'] == 'Nam',
                  )
                  .length;
          _femaleUsers =
              snapshot.docs
                  .where(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['gender'] ==
                            'Female' ||
                        (doc.data() as Map<String, dynamic>)['gender'] == 'Nữ',
                  )
                  .length;
        });
      }
    });
  }

  Future<void> _logout() async {
    final lang = _language;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(lang == 'vi' ? 'Xác nhận đăng xuất' : 'Confirm Logout'),
            content: Text(
              lang == 'vi'
                  ? 'Bạn có chắc chắn muốn đăng xuất không?'
                  : 'Are you sure you want to log out?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  lang == 'vi' ? 'Hủy' : 'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  lang == 'vi' ? 'Đăng xuất' : 'Logout',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('phone');
      await prefs.remove('email');
      await prefs.remove('userRole');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _language;
    final isVi = lang == 'vi'; // true nếu đang ở tiếng Việt

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          isVi ? 'Quản lý hệ thống' : 'System Management',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          // PopupMenu để chọn ngôn ngữ
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (value) {
              // Khi chọn “vi” hoặc “en”, gọi setState để thay đổi ngôn ngữ
              setState(() {
                _language = value;
              });
            },
            itemBuilder:
                (context) => [
                  // Dùng PopupMenuItem với child: Text(...) để tránh fractional translation
                  PopupMenuItem<String>(value: 'vi', child: Text('Vietnamese')),
                  PopupMenuItem<String>(value: 'en', child: Text('English')),
                ],
          ),

          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: isVi ? 'Đăng xuất' : 'Logout',
          ),
        ],
      ),

      body: Column(
        children: [
          // Header thống kê người dùng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  isVi ? 'Thống kê người dùng' : 'User Statistics',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        isVi ? 'Tổng số' : 'Total',
                        _totalUsers.toString(),
                        Icons.people,
                        Colors.blue[600]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        isVi ? 'Nam' : 'Male',
                        _maleUsers.toString(),
                        Icons.male,
                        Colors.indigo[600]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        isVi ? 'Nữ' : 'Female',
                        _femaleUsers.toString(),
                        Icons.female,
                        Colors.pink[600]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách người dùng
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi ? 'Danh sách người dùng' : 'User List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .orderBy('name')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isVi
                                      ? 'Chưa có người dùng nào'
                                      : 'No users yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final users = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user =
                                users[index].data() as Map<String, dynamic>;
                            final isAdmin = user['role'] == 'admin';

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        isAdmin
                                            ? Colors.orange[100]
                                            : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color:
                                        isAdmin
                                            ? Colors.orange[700]
                                            : Colors.blue[700],
                                    size: 24,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['name'] ??
                                            (isVi ? 'Chưa có tên' : 'No Name'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[600],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          isVi ? 'ADMIN' : 'ADMIN',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['phone'] ??
                                              (isVi ? 'Không có' : 'N/A'),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          user['gender'] == 'Male' ||
                                                  user['gender'] == 'Nam'
                                              ? Icons.male
                                              : Icons.female,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['gender'] ??
                                              (isVi
                                                  ? 'Không xác định'
                                                  : 'Unknown'),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (user['birthYear'] != null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.cake,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isVi
                                                ? 'Sinh năm ${user['birthYear']}'
                                                : 'Born ${user['birthYear']}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.blue[800],
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => UserDetailScreen(
                                            userId: users[index].id,
                                            userData: user,
                                            language: _language,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
