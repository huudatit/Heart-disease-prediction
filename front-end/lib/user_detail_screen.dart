import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final String language; // 'vi' hoặc 'en'

  const UserDetailScreen({
    Key? key,
    required this.userId,
    required this.userData,
    required this.language,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Map<String, dynamic>> healthRecords = [];
  bool isLoading = true;
  int totalDiagnoses = 0;
  int highRiskCount = 0;
  int normalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserHealthRecords();
  }

  Future<void> _loadUserHealthRecords() async {
    try {
      setState(() => isLoading = true);

      final healthRecordsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('health_records')
              .where('timestamp', isNotEqualTo: null)
              .orderBy('timestamp', descending: true)
              .get();

      List<Map<String, dynamic>> records = [];
      int highRisk = 0;
      int normal = 0;

      for (var doc in healthRecordsSnapshot.docs) {
        final data = doc.data();
        records.add({'recordId': doc.id, ...data});

        // Đếm số lần chẩn đoán theo kết quả
        if (data['prediction'] == 1) {
          highRisk++;
        } else if (data['prediction'] == 0) {
          normal++;
        }
      }

      setState(() {
        healthRecords = records;
        totalDiagnoses = records.length;
        highRiskCount = highRisk;
        normalCount = normal;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user health records: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'vi'
                ? 'Lỗi khi tải dữ liệu: $e'
                : 'Error loading data: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userData['role'] == 'admin';
    final lang = widget.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.userData['name'] ??
              (lang == 'vi' ? 'Chi tiết người dùng' : 'User Details'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserHealthRecords,
            tooltip: lang == 'vi' ? 'Tải lại' : 'Refresh',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // User Info Card
                    _buildUserInfoCard(isAdmin, lang),

                    // Statistics Cards
                    _buildStatisticsCards(lang),

                    // Health Records List
                    _buildHealthRecordsList(lang),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserInfoCard(bool isAdmin, String lang) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar và tên
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isAdmin ? Colors.orange[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: isAdmin ? Colors.orange[700] : Colors.blue[700],
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.userData['name'] ??
                                (lang == 'vi' ? 'Chưa có tên' : 'No Name'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lang == 'vi' ? 'ADMIN' : 'ADMIN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${lang == 'vi' ? 'ID' : 'ID'}: ${widget.userData['userid'] ?? widget.userId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Thông tin chi tiết
          _buildInfoRow(
            Icons.phone,
            lang == 'vi' ? 'Số điện thoại' : 'Phone',
            widget.userData['phone'] ?? (lang == 'vi' ? 'Chưa có' : 'N/A'),
          ),
          _buildInfoRow(
            Icons.email,
            'Email',
            widget.userData['email'] ?? (lang == 'vi' ? 'Chưa có' : 'N/A'),
          ),
          _buildInfoRow(
            widget.userData['gender'] == 'Male' ||
                    widget.userData['gender'] == 'Nam'
                ? Icons.male
                : Icons.female,
            lang == 'vi' ? 'Giới tính' : 'Gender',
            widget.userData['gender'] ??
                (lang == 'vi' ? 'Chưa xác định' : 'Unknown'),
          ),
          if (widget.userData['birthYear'] != null)
            _buildInfoRow(
              Icons.cake,
              lang == 'vi' ? 'Năm sinh' : 'Birth Year',
              widget.userData['birthYear'].toString(),
            ),
          if (widget.userData['age'] != null)
            _buildInfoRow(
              Icons.person_outline,
              lang == 'vi' ? 'Tuổi' : 'Age',
              '${widget.userData['age']}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lang == 'vi' ? 'Tổng số lần' : 'Total',
              totalDiagnoses.toString(),
              Icons.analytics,
              Colors.blue[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang == 'vi' ? 'Có nguy cơ' : 'High Risk',
              highRiskCount.toString(),
              Icons.warning,
              Colors.red[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang == 'vi' ? 'Bình thường' : 'Normal',
              normalCount.toString(),
              Icons.check_circle,
              Colors.green[600]!,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordsList(String lang) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Text(
                  lang == 'vi' ? 'Lịch sử chẩn đoán' : 'Diagnosis History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),

          if (healthRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang == 'vi'
                          ? 'Chưa có dữ liệu chẩn đoán'
                          : 'No diagnosis data',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: healthRecords.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                    indent: 16,
                    endIndent: 16,
                  ),
              itemBuilder: (context, index) {
                final record = healthRecords[index];
                return _buildHealthRecordItem(record, index + 1, lang);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordItem(
    Map<String, dynamic> record,
    int index,
    String lang,
  ) {
    // Lấy giá trị prediction và probability (nếu có)
    final int? pred =
        record['prediction'] != null
            ? (record['prediction'] as num).toInt()
            : null;
    final double? prob =
        record['probability'] != null
            ? (record['probability'] as num).toDouble()
            : null;

    final bool hasRisk = pred == 1;
    final bool isNormal = pred == 0;

    // Lấy ngày giờ: ưu tiên 'timestamp', nếu không có thì fallback về 'created_at'
    final dynamic ts = record['timestamp'] ?? record['created_at'];
    final String dateStr = _formatDateTime(ts);

    // Tạo dòng subtitle:
    // - Nếu đã có prediction, hiển thị: "dd/MM/yyyy HH:mm  ·  xx.x%"
    // - Nếu chưa có prediction, chỉ hiển thị: "dd/MM/yyyy HH:mm"
    String subtitleText;
    if (pred == null || prob == null) {
      subtitleText = dateStr;
    } else {
      final percent = (prob * 100).toStringAsFixed(1);
      subtitleText = '$dateStr · $percent%';
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          // Vòng số thứ tự
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  hasRisk
                      ? Colors.red[100]
                      : (isNormal ? Colors.green[100] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      hasRisk
                          ? Colors.red[700]
                          : (isNormal ? Colors.green[700] : Colors.grey[600]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Phần chính: "Chẩn đoán #n" và subtitle (ngày/giờ ± %)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'vi' ? 'Chẩn đoán #$index' : 'Diagnosis #$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Nếu đã có kết quả (pred != null), mới show badge “Bình thường” hoặc “Có nguy cơ”
          if (pred != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasRisk ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasRisk ? Colors.red[200]! : Colors.green[200]!,
                ),
              ),
              child: Text(
                hasRisk
                    ? (lang == 'vi' ? 'Có nguy cơ' : 'High Risk')
                    : (lang == 'vi' ? 'Bình thường' : 'Normal'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: hasRisk ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ),

          // Nếu chưa có prediction thì không show badge
        ],
      ),
      children: [_buildHealthDetailTable(record, lang)],
    );
  }

  Widget _buildHealthDetailTable(Map<String, dynamic> record, String lang) {
    // Lấy map nested "input_data"
    final input = record['input_data'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              lang == 'vi' ? 'Chi tiết thông số' : 'Measurement Details',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children: [
              // Loại đau ngực: record['input_data']['cp']
              _buildTableRow(
                lang == 'vi' ? 'Loại đau ngực' : 'Chest Pain',
                _getChestPainDescription(input?['cp'], lang),
              ),

              // Huyết áp nghỉ: record['input_data']['trestbps']
              _buildTableRow(
                lang == 'vi' ? 'Huyết áp nghỉ' : 'Resting BP',
                input != null && input['trestbps'] != null
                    ? '${input['trestbps']} mmHg'
                    : (lang == 'vi' ? 'N/A' : 'N/A'),
              ),

              // Cholesterol: record['input_data']['chol']
              _buildTableRow(
                lang == 'vi' ? 'Cholesterol' : 'Cholesterol',
                input != null && input['chol'] != null
                    ? '${input['chol']} mg/dL'
                    : (lang == 'vi' ? 'N/A' : 'N/A'),
              ),

              // Đường huyết đói: record['input_data']['fbs']
              _buildTableRow(
                lang == 'vi' ? 'Đường huyết đói' : 'Fasting Blood Sugar',
                _getFbsDescription(input?['fbs'], lang),
              ),

              // Điện tâm đồ nghỉ: record['input_data']['restecg']
              _buildTableRow(
                lang == 'vi' ? 'Điện tâm đồ nghỉ' : 'Rest ECG',
                _getRestEcgDescription(input?['restecg'], lang),
              ),

              // Nhịp tim tối đa: record['input_data']['thalach']
              _buildTableRow(
                lang == 'vi' ? 'Nhịp tim tối đa' : 'Max Heart Rate',
                input != null && input['thalach'] != null
                    ? '${input['thalach']} bpm'
                    : (lang == 'vi' ? 'N/A' : 'N/A'),
              ),

              // Exercise Angina: record['input_data']['exang']
              _buildTableRow(
                lang == 'vi' ? 'Đau khi vận động' : 'Exercise Angina',
                _getExangDescription(input?['exang'], lang),
              ),

              // ST Depression: record['input_data']['oldpeak']
              _buildTableRow(
                lang == 'vi' ? 'ST Depression' : 'ST Depression',
                input != null && input['oldpeak'] != null
                    ? input['oldpeak'].toString()
                    : (lang == 'vi' ? 'N/A' : 'N/A'),
              ),

              // ST Slope: record['input_data']['slope']
              _buildTableRow(
                lang == 'vi' ? 'Dốc ST' : 'ST Slope',
                _getSlopeDescription(input?['slope'], lang),
              ),

              // Major Vessels: record['input_data']['ca']
              _buildTableRow(
                lang == 'vi' ? 'Số mạch máu chính' : 'Major Vessels',
                input != null && input['ca'] != null
                    ? input['ca'].toString()
                    : (lang == 'vi' ? 'N/A' : 'N/A'),
              ),

              // Thalassemia: record['input_data']['thal']
              _buildTableRow(
                lang == 'vi' ? 'Thalassemia' : 'Thalassemia',
                _getThalDescription(input?['thal'], lang),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return widget.language == 'vi' ? 'Chưa có' : 'N/A';

    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is Timestamp) {
        dt = dateTime.toDate();
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return widget.language == 'vi' ? 'Chưa có' : 'N/A';
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return widget.language == 'vi' ? 'Chưa có' : 'N/A';
    }
  }

  // Helper methods for data description
  String _getChestPainDescription(dynamic cp, String lang) {
    if (cp == null) return lang == 'vi' ? 'N/A' : 'N/A';
    final descriptionsVi = {
      '0': 'Đau thắt ngực điển hình',
      '1': 'Đau thắt ngực không điển hình',
      '2': 'Đau không do thắt ngực',
      '3': 'Không triệu chứng',
    };
    final descriptionsEn = {
      '0': 'Typical angina',
      '1': 'Atypical angina',
      '2': 'Non-anginal pain',
      '3': 'Asymptomatic',
    };
    return lang == 'vi'
        ? (descriptionsVi[cp.toString()] ?? cp.toString())
        : (descriptionsEn[cp.toString()] ?? cp.toString());
  }

  String _getFbsDescription(dynamic fbs, String lang) {
    if (fbs == null) return lang == 'vi' ? 'Chưa nhập' : 'Not entered';
    if (fbs.toString() == '1') {
      return lang == 'vi' ? '> 120 mg/dL' : '> 120 mg/dL';
    }
    if (fbs.toString() == '0') {
      return lang == 'vi' ? '≤ 120 mg/dL' : '≤ 120 mg/dL';
    }
    return fbs.toString();
  }

  String _getRestEcgDescription(dynamic restecg, String lang) {
    if (restecg == null) return lang == 'vi' ? 'Chưa nhập' : 'Not entered';
    final descriptionsVi = {
      '0': 'Bình thường',
      '1': 'Bất thường ST-T',
      '2': 'Phì đại thất trái',
    };
    final descriptionsEn = {
      '0': 'Normal',
      '1': 'ST-T abnormality',
      '2': 'Left ventricular hypertrophy',
    };
    return lang == 'vi'
        ? (descriptionsVi[restecg.toString()] ?? restecg.toString())
        : (descriptionsEn[restecg.toString()] ?? restecg.toString());
  }

  String _getExangDescription(dynamic exang, String lang) {
    if (exang == null) return lang == 'vi' ? 'Chưa nhập' : 'Not entered';
    if (exang.toString() == '1') return lang == 'vi' ? 'Có' : 'Yes';
    if (exang.toString() == '0') return lang == 'vi' ? 'Không' : 'No';
    return exang.toString();
  }

  String _getSlopeDescription(dynamic slope, String lang) {
    if (slope == null) return lang == 'vi' ? 'Chưa nhập' : 'Not entered';
    final descriptionsVi = {'0': 'Dốc lên', '1': 'Phẳng', '2': 'Dốc xuống'};
    final descriptionsEn = {'0': 'Upsloping', '1': 'Flat', '2': 'Downsloping'};
    return lang == 'vi'
        ? (descriptionsVi[slope.toString()] ?? slope.toString())
        : (descriptionsEn[slope.toString()] ?? slope.toString());
  }

  String _getThalDescription(dynamic thal, String lang) {
    if (thal == null) return lang == 'vi' ? 'Chưa nhập' : 'Not entered';
    final descriptionsVi = {
      '1': 'Bình thường',
      '2': 'Khiếm khuyết cố định',
      '3': 'Khiếm khuyết có thể phục hồi',
    };
    final descriptionsEn = {
      '1': 'Normal',
      '2': 'Fixed defect',
      '3': 'Reversible defect',
    };
    return lang == 'vi'
        ? (descriptionsVi[thal.toString()] ?? thal.toString())
        : (descriptionsEn[thal.toString()] ?? thal.toString());
  }
}
