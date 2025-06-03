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
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> userData;
  String _language = 'en';
  String? lastUpdated;

  final Map<String, Map<String, String>> metrics = {'en': {}, 'vi': {}};

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

  // Cải tiến method để lưu thông tin sức khỏe vào subcollection
  void _saveHealthDataToFirestore() async {
    final prefs = await SharedPreferences.getInstance();

    // Kiểm tra xem có dữ liệu sức khỏe không
    final age = prefs.getString('age');
    if (age == null) return; // Không có dữ liệu thì không lưu

    // Lấy tất cả dữ liệu sức khỏe từ SharedPreferences
    final healthData = {
      'age': age,
      'sex': prefs.getString('sex'),
      'cp': prefs.getString('cp'),
      'trestbps': prefs.getString('trestbps'),
      'chol': prefs.getString('chol'),
      'fbs': prefs.getString('fbs'),
      'restecg': prefs.getString('restecg'),
      'thalach': prefs.getString('thalach'),
      'exang': prefs.getString('exang'),
      'oldpeak': prefs.getString('oldpeak'),
      'slope': prefs.getString('slope'),
      'ca': prefs.getString('ca'),
      'thal': prefs.getString('thal'),
      'input_date': prefs.getString('last_updated'),
      'created_at': FieldValue.serverTimestamp(),
      'user_info': {
        'name': userData['name'],
        'phone': userData['phone'],
        'user_age': userData['age'],
      },
    };

    try {
      // Tìm user document
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: userData['phone'])
              .get();

      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id;

        // Tạo một document mới trong subcollection 'health_records'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .collection('health_records')
            .add(healthData);

        // Cập nhật thông tin lần khám cuối vào user document
        await userQuery.docs.first.reference.update({
          'last_health_check': FieldValue.serverTimestamp(),
          'total_health_records': FieldValue.increment(1),
        });

        print('Health data saved to subcollection successfully');
      }
    } catch (e) {
      print('Error saving health data to Firestore: $e');
    }
  }

  // Method để lấy lịch sử khám bệnh
  Future<List<Map<String, dynamic>>> _getHealthHistory() async {
    try {
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: userData['phone'])
              .get();

      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id;

        final healthRecords =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userDocId)
                .collection('health_records')
                .orderBy('created_at', descending: true)
                .limit(10) // Lấy 10 bản ghi gần nhất
                .get();

        return healthRecords.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    } catch (e) {
      print('Error fetching health history: $e');
    }
    return [];
  }

  // Method để hiển thị lịch sử khám bệnh
  void _showHealthHistory() async {
    final history = await _getHealthHistory();

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _language == 'vi' ? 'Lịch sử khám bệnh' : 'Health History',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child:
                  history.isEmpty
                      ? Center(
                        child: Text(
                          _language == 'vi'
                              ? 'Chưa có lịch sử khám bệnh'
                              : 'No health history available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final record = history[index];
                          final createdAt = record['created_at'] as Timestamp?;
                          final dateStr =
                              createdAt != null
                                  ? DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(createdAt.toDate())
                                  : 'N/A';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Icon(
                                  Icons.health_and_safety,
                                  color: Colors.blue[800],
                                ),
                              ),
                              title: Text(
                                '${_language == 'vi' ? 'Khám ngày' : 'Check-up on'} $dateStr',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${_language == 'vi' ? 'Tuổi' : 'Age'}: ${record['age']}, '
                                '${_language == 'vi' ? 'Huyết áp' : 'BP'}: ${record['trestbps'] ?? 'N/A'}',
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              onTap: () => _showHealthRecordDetail(record),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _language == 'vi' ? 'Đóng' : 'Close',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
    );
  }

  // Method để hiển thị chi tiết một bản ghi khám bệnh
  void _showHealthRecordDetail(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _language == 'vi'
                  ? 'Chi tiết khám bệnh'
                  : 'Health Record Details',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Tuổi' : 'Age'}:',
                      '${record['age']} ${_language == 'vi' ? 'tuổi' : 'years'}',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Giới tính' : 'Sex'}:',
                      _getSexDescription(record['sex']),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Đau ngực' : 'Chest Pain'}:',
                      _getChestPainDescription(record['cp'], _language),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Huyết áp nghỉ' : 'Resting BP'}:',
                      '${record['trestbps'] ?? 'N/A'} mmHg',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Cholesterol' : 'Cholesterol'}:',
                      '${record['chol'] ?? 'N/A'} mg/dL',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Đường huyết đói' : 'Fasting Blood Sugar'}:',
                      _getFbsDescription(record['fbs'], _language),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Điện tâm đồ' : 'Rest ECG'}:',
                      _getRestEcgDescription(record['restecg'], _language),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Nhịp tim tối đa' : 'Max Heart Rate'}:',
                      '${record['thalach'] ?? 'N/A'} bpm',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Đau khi vận động' : 'Exercise Angina'}:',
                      _getExangDescription(record['exang']),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'ST giảm' : 'ST Depression'}:',
                      record['oldpeak'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Dốc ST' : 'ST Slope'}:',
                      _getSlopeDescription(record['slope'], _language),
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Số mạch chính' : 'Major Vessels'}:',
                      record['ca'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '${_language == 'vi' ? 'Thalassemia' : 'Thalassemia'}:',
                      _getThalDescription(record['thal'], _language),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _language == 'vi' ? 'Đóng' : 'Close',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _loadMetricsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdated = prefs.getString('last_updated');

      // Kiểm tra nếu có data mới thì hiển thị, không thì hiển thị default
      final age = prefs.getString('age');
      final sex = prefs.getString('sex');
      final cp = prefs.getString('cp');
      final trestbps = prefs.getString('trestbps');
      final chol = prefs.getString('chol');
      final fbs = prefs.getString('fbs');
      final restecg = prefs.getString('restecg');
      final thalach = prefs.getString('thalach');
      final exang = prefs.getString('exang');
      final oldpeak = prefs.getString('oldpeak');
      final slope = prefs.getString('slope');
      final ca = prefs.getString('ca');
      final thal = prefs.getString('thal');

      metrics['en'] = {
        "Age": age != null ? "$age years" : "Not entered",
        "Sex": _getSexDescription(sex),
        "Chest Pain": _getChestPainDescription(cp, 'en'),
        "Resting BP": trestbps != null ? "$trestbps mmHg" : "Not entered",
        "Cholesterol": chol != null ? "$chol mg/dL" : "Not entered",
        "Fasting Blood Sugar": _getFbsDescription(fbs, 'en'),
        "Rest ECG": _getRestEcgDescription(restecg, 'en'),
        "Max Heart Rate": thalach != null ? "$thalach bpm" : "Not entered",
        "Exercise Angina": _getExangDescription(exang),
        "ST Depression": oldpeak ?? "Not entered",
        "ST Slope": _getSlopeDescription(slope, 'en'),
        "Major Vessels": ca ?? "Not entered",
        "Thalassemia": _getThalDescription(thal, 'en'),
      };

      metrics['vi'] = {
        "Tuổi": age != null ? "$age tuổi" : "Chưa nhập",
        "Giới tính":
            sex == '1'
                ? "Nam"
                : sex == '0'
                ? "Nữ"
                : "Chưa nhập",
        "Đau ngực": _getChestPainDescription(cp, 'vi'),
        "Huyết áp nghỉ": trestbps != null ? "$trestbps mmHg" : "Chưa nhập",
        "Cholesterol": chol != null ? "$chol mg/dL" : "Chưa nhập",
        "Đường huyết đói": _getFbsDescription(fbs, 'vi'),
        "Điện tâm đồ": _getRestEcgDescription(restecg, 'vi'),
        "Nhịp tim tối đa": thalach != null ? "$thalach bpm" : "Chưa nhập",
        "Đau khi vận động":
            exang == '1'
                ? "Có"
                : exang == '0'
                ? "Không"
                : "Chưa nhập",
        "ST giảm": oldpeak ?? "Chưa nhập",
        "Dốc ST": _getSlopeDescription(slope, 'vi'),
        "Số mạch chính": ca ?? "Chưa nhập",
        "Thalassemia": _getThalDescription(thal, 'vi'),
      };
    });

    // Lưu dữ liệu vào Firestore subcollection mỗi khi có dữ liệu mới
    _saveHealthDataToFirestore();
  }

  // Helper methods để mô tả các giá trị
  String _getSexDescription(String? sex) {
    if (sex == '1') return _language == 'vi' ? "Nam" : "Male";
    if (sex == '0') return _language == 'vi' ? "Nữ" : "Female";
    return _language == 'vi' ? "Chưa nhập" : "Not entered";
  }

  String _getExangDescription(String? exang) {
    if (exang == '1') return _language == 'vi' ? "Có" : "Yes";
    if (exang == '0') return _language == 'vi' ? "Không" : "No";
    return _language == 'vi' ? "Chưa nhập" : "Not entered";
  }

  String _getChestPainDescription(String? cp, String lang) {
    if (cp == null) return lang == 'vi' ? "Chưa nhập" : "Not entered";

    final descriptions = {
      'en': {
        '0': 'Typical angina',
        '1': 'Atypical angina',
        '2': 'Non-anginal pain',
        '3': 'Asymptomatic',
      },
      'vi': {
        '0': 'Đau thắt ngực điển hình',
        '1': 'Đau thắt ngực không điển hình',
        '2': 'Đau không do thắt ngực',
        '3': 'Không triệu chứng',
      },
    };

    return descriptions[lang]?[cp] ?? cp;
  }

  String _getFbsDescription(String? fbs, String lang) {
    if (fbs == null) return lang == 'vi' ? "Chưa nhập" : "Not entered";

    if (fbs == '1') {
      return lang == 'vi' ? "> 120 mg/dL" : "> 120 mg/dL";
    } else if (fbs == '0') {
      return lang == 'vi' ? "≤ 120 mg/dL" : "≤ 120 mg/dL";
    }
    return fbs;
  }

  String _getRestEcgDescription(String? restecg, String lang) {
    if (restecg == null) return lang == 'vi' ? "Chưa nhập" : "Not entered";

    final descriptions = {
      'en': {
        '0': 'Normal',
        '1': 'ST-T abnormality',
        '2': 'Left ventricular hypertrophy',
      },
      'vi': {
        '0': 'Bình thường',
        '1': 'Bất thường ST-T',
        '2': 'Phì đại thất trái',
      },
    };

    return descriptions[lang]?[restecg] ?? restecg;
  }

  String _getSlopeDescription(String? slope, String lang) {
    if (slope == null) return lang == 'vi' ? "Chưa nhập" : "Not entered";

    final descriptions = {
      'en': {'0': 'Upsloping', '1': 'Flat', '2': 'Downsloping'},
      'vi': {'0': 'Dốc lên', '1': 'Phẳng', '2': 'Dốc xuống'},
    };

    return descriptions[lang]?[slope] ?? slope;
  }

  String _getThalDescription(String? thal, String lang) {
    if (thal == null) return lang == 'vi' ? "Chưa nhập" : "Not entered";

    final descriptions = {
      'en': {'1': 'Normal', '2': 'Fixed defect', '3': 'Reversible defect'},
      'vi': {
        '1': 'Bình thường',
        '2': 'Khiếm khuyết cố định',
        '3': 'Khiếm khuyết có thể phục hồi',
      },
    };

    return descriptions[lang]?[thal] ?? thal;
  }

  String getFormattedLastUpdated() {
    if (lastUpdated == null) return '';
    try {
      final dateTime = DateTime.parse(lastUpdated!);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
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
                                  'updated_at': FieldValue.serverTimestamp(),
                                });

                                setState(() {
                                  userData['name'] = nameController.text;
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
    final url = Uri.parse('http://192.168.1.120:5000/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(input),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prediction = data['prediction'];
        final probability = data['probability'];

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
                        // Sử dụng Navigator.push và chờ kết quả trả về
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InputFormScreen(),
                          ),
                        );

                        // Sau khi quay lại từ InputFormScreen, reload dữ liệu
                        _loadMetricsFromPrefs();
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
                              builder:
                                  (_) => const ResultScreen(
                                    prediction: 1,
                                    probability: 0.85,
                                    inputData: {},
                                  ),
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Last Updated Info
              if (lastUpdated != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    "${_language == 'vi' ? 'Cập nhật lần cuối' : 'Last updated'}: ${getFormattedLastUpdated()}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: selectedMetrics.length,
                itemBuilder: (context, index) {
                  final entry = selectedMetrics.entries.toList()[index];
                  final isNotEntered =
                      entry.value.contains('Not entered') ||
                      entry.value.contains('Chưa nhập');

                  return Container(
                    decoration: BoxDecoration(
                      color: isNotEntered ? Colors.grey[200] : cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color:
                                  isNotEntered
                                      ? Colors.grey[600]
                                      : (isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isNotEntered
                                      ? Colors.grey[500]
                                      : (isDarkMode
                                          ? Colors.white70
                                          : Colors.black87),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
