import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dacn_app/info_screen.dart';
import 'result_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'input_form_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> userData;
  String _language = 'en';

  final Map<String, Map<String, String>> metrics = {
    'en': {
      "Age": "56 years",
      "Sex": "Male",
      "Chest Pain": "No",
      "Resting BP": "130 mmHg",
      "Cholesterol": "250 mg/dL",
      "Fasting Blood Sugar": "105 mg/dL",
      "Rest ECG": "Normal",
      "Max Heart Rate": "150 bpm",
      "Exercise Angina": "No",
      "Oldpeak": "2.3",
      "ST Slope": "1",
      "Major Vessels": "0",
      "Thalassemia": "Normal",
    },
    'vi': {
      "Tuổi": "56 tuổi",
      "Giới tính": "Nam",
      "Đau ngực": "Không",
      "Huyết áp nghỉ": "130 mmHg",
      "Cholesterol": "250 mg/dL",
      "Đường huyết đói": "105 mg/dL",
      "Điện tâm đồ": "Bình thường",
      "Nhịp tim tối đa": "150 bpm",
      "Đau khi vận động": "Không",
      "ST giảm": "2.3",
      "Dốc ST": "1",
      "Số mạch chính": "0",
      "Thalassemia": "Bình thường",
    },
  };

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
    _loadMetricsFromPrefs();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phone');
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _loadMetricsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      metrics['en'] = {
        "Age": "${prefs.getString('age') ?? '56'} years",
        "Sex": prefs.getString('sex') == '1' ? "Male" : "Female",
        "Chest Pain": prefs.getString('cp') ?? "No",
        "Resting BP": "${prefs.getString('trestbps') ?? '130'} mmHg",
        "Cholesterol": "${prefs.getString('chol') ?? '250'} mg/dL",
        "Fasting Blood Sugar": "${prefs.getString('fbs') ?? '105'} mg/dL",
        "Rest ECG": prefs.getString('restecg') ?? "Normal",
        "Max Heart Rate": "${prefs.getString('thalach') ?? '150'} bpm",
        "Exercise Angina": prefs.getString('exang') ?? "No",
        "Oldpeak": prefs.getString('oldpeak') ?? "2.3",
        "ST Slope": prefs.getString('slope') ?? "1",
        "Major Vessels": prefs.getString('ca') ?? "0",
        "Thalassemia": prefs.getString('thal') ?? "Normal",
      };

      metrics['vi'] = {
        "Tuổi": "${prefs.getString('age') ?? '56'} tuổi",
        "Giới tính": prefs.getString('sex') == '1' ? "Nam" : "Nữ",
        "Đau ngực": prefs.getString('cp') ?? "Không",
        "Huyết áp nghỉ": "${prefs.getString('trestbps') ?? '130'} mmHg",
        "Cholesterol": "${prefs.getString('chol') ?? '250'} mg/dL",
        "Đường huyết đói": "${prefs.getString('fbs') ?? '105'} mg/dL",
        "Điện tâm đồ": prefs.getString('restecg') ?? "Bình thường",
        "Nhịp tim tối đa": "${prefs.getString('thalach') ?? '150'} bpm",
        "Đau khi vận động": prefs.getString('exang') ?? "Không",
        "ST giảm": prefs.getString('oldpeak') ?? "2.3",
        "Dốc ST": prefs.getString('slope') ?? "1",
        "Số mạch chính": prefs.getString('ca') ?? "0",
        "Thalassemia": prefs.getString('thal') ?? "Bình thường",
      };
    });
  }

  void _showEditUserDialog() {
    final nameController = TextEditingController(text: userData['name']);
    final emailController = TextEditingController(text: userData['email']);
    final phoneController = TextEditingController(text: userData['phone']);
    final ageController = TextEditingController(
      text: userData['age'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.blue[100]!, width: 1),
                ),
              ),
              child: Text(
                _language == 'vi' ? "Cập nhật thông tin" : "Update Information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thêm trường tên
                _buildStyledTextField(
                  controller: nameController,
                  label: _language == 'vi' ? "Họ và tên" : "Name",
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: emailController,
                  label: _language == 'vi' ? "Email" : "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: phoneController,
                  label: _language == 'vi' ? "Số điện thoại" : "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: ageController,
                  label: _language == 'vi' ? "Tuổi" : "Age",
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.blue[800]!),
                        ),
                      ),
                      child: Text(
                        _language == 'vi' ? "Hủy" : "Cancel",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await FirebaseFirestore.instance
                            .collection('users')
                            .where('phone', isEqualTo: userData['phone'])
                            .get()
                            .then((snapshot) {
                              if (snapshot.docs.isNotEmpty) {
                                snapshot.docs.first.reference.update({
                                  'name': nameController.text, 
                                  'email': emailController.text,
                                  'phone': phoneController.text,
                                  'age':
                                      int.tryParse(ageController.text) ??
                                      userData['age'],
                                });

                                setState(() {
                                  userData['name'] =
                                      nameController.text; 
                                  userData['email'] = emailController.text;
                                  userData['phone'] = phoneController.text;
                                  userData['age'] =
                                      int.tryParse(ageController.text) ??
                                      userData['age'];
                                });
                              }
                            });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _language == 'vi'
                                  ? 'Cập nhật thành công'
                                  : 'Update successful',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _language == 'vi' ? "Lưu" : "Save",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  // Helper method to create styled text fields
  Widget _buildStyledTextField({
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
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 10, right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue[800], size: 24),
          ),
          labelStyle: TextStyle(color: Colors.blue[800], fontSize: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.blue[800], fontSize: 16),
      ),
    );
  }

  void predictHeartDisease(Map<String, dynamic> input) async {
    final url = Uri.parse(
      'http://192.168.1.36:5000/predict',
    ); // Cập nhật địa chỉ backend

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(input),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prediction = data['prediction']; // int (0 hoặc 1)
        final probability = data['probability']; // double
        // input là inputData bạn đã gửi

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ResultScreen(
                  prediction: prediction,
                  probability: probability.toDouble(),
                  inputData: input,
                ),
          ),
        );
      } else {
        throw Exception("Lỗi từ server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi gọi API: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể kết nối máy chủ")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final selectedMetrics = metrics[_language]!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _language == 'vi' ? "Trang chính" : "Home",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              if (value == 'language') {
                setState(() {
                  _language = _language == 'vi' ? 'en' : 'vi';
                });
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'language',
                    child: Text(_language == 'vi' ? 'Tiếng Anh' : 'Vietnamese'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(_language == 'vi' ? 'Đăng xuất' : 'Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Card(
                elevation: 4,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 40,

                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue[500],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'] ?? "User",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${_language == 'vi' ? "SĐT" : "Phone"}: ${userData['phone']} | ${_language == 'vi' ? "Tuổi" : "Age"}: ${userData['age']}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[600]),
                        onPressed: _showEditUserDialog,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.info_outline,
                      title:
                          _language == 'vi'
                              ? "Nhập thông tin sức khỏe"
                              : "Health Input",
                      color: Colors.blue,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InputFormScreen(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            metrics['en'] = {
                              "Age": "${result['age']} years",
                              "Sex": result['sex'] == '1' ? "Male" : "Female",
                              "Chest Pain": result['cp'] == '1' ? "Yes" : "No",
                              "Resting BP": "${result['trestbps']} mmHg",
                              "Cholesterol": "${result['chol']} mg/dL",
                              "Fasting Blood Sugar": "${result['fbs']} mg/dL",
                              "Rest ECG": "${result['restecg']}",
                              "Max Heart Rate": "${result['thalach']} bpm",
                              "Exercise Angina":
                                  result['exang'] == '1' ? "Yes" : "No",
                              "Oldpeak": "${result['oldpeak']}",
                              "ST Slope": "${result['slope']}",
                              "Major Vessels": "${result['ca']}",
                              "Thalassemia": "${result['thal']}",
                            };
                          });

                          // Gọi API backend
                          predictHeartDisease(result);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.analytics,
                      title:
                          _language == 'vi'
                              ? "Kết quả dự đoán"
                              : "Prediction Results",
                      color: Colors.deepOrange,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResultScreen(
                                prediction: 1, // Hoặc giá trị thật
                                probability: 0.85, // Hoặc giá trị thật
                                inputData:
                                  {}, // Hoặc dữ liệu thật bạn muốn truyền
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Metrics Section
              Text(
                _language == 'vi' ? "Các chỉ số đo:" : "Measured Metrics:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: selectedMetrics.length,
                itemBuilder: (context, index) {
                  final entry = selectedMetrics.entries.toList()[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "${entry.key}: ${entry.value}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.3),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
