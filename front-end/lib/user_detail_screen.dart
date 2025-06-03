import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    Key? key,
    required this.userId,
    required this.userData,
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
              .orderBy('created_at', descending: true)
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userData['role'] == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.userData['name'] ?? 'Chi tiết người dùng',
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
                    _buildUserInfoCard(isAdmin),

                    // Statistics Cards
                    _buildStatisticsCards(),

                    // Health Records List
                    _buildHealthRecordsList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserInfoCard(bool isAdmin) {
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
                            widget.userData['name'] ?? 'Chưa có tên',
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
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
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
                      'ID: ${widget.userId}',
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
            'Số điện thoại',
            widget.userData['phone'] ?? 'Chưa có',
          ),
          _buildInfoRow(
            Icons.email,
            'Email',
            widget.userData['email'] ?? 'Chưa có',
          ),
          _buildInfoRow(
            widget.userData['gender'] == 'Male' ||
                    widget.userData['gender'] == 'Nam'
                ? Icons.male
                : Icons.female,
            'Giới tính',
            widget.userData['gender'] ?? 'Chưa xác định',
          ),
          if (widget.userData['birthYear'] != null)
            _buildInfoRow(
              Icons.cake,
              'Năm sinh',
              widget.userData['birthYear'].toString(),
            ),
          if (widget.userData['age'] != null)
            _buildInfoRow(
              Icons.person_outline,
              'Tuổi',
              '${widget.userData['age']} tuổi',
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

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng số lần',
              totalDiagnoses.toString(),
              Icons.analytics,
              Colors.blue[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Có nguy cơ',
              highRiskCount.toString(),
              Icons.warning,
              Colors.red[600]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Bình thường',
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

  Widget _buildHealthRecordsList() {
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
                  'Lịch sử chẩn đoán',
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
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu chẩn đoán',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
                return _buildHealthRecordItem(record, index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordItem(Map<String, dynamic> record, int index) {
    final hasRisk = record['target'] == 1;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: hasRisk ? Colors.red[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasRisk ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chẩn đoán #$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(record['created_at']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
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
              hasRisk ? 'Có nguy cơ' : 'Bình thường',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: hasRisk ? Colors.red[700] : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
      children: [_buildHealthDetailTable(record)],
    );
  }

  Widget _buildHealthDetailTable(Map<String, dynamic> record) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Chi tiết thông số',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children: [
              _buildTableRow(
                'Loại đau ngực',
                _getChestPainDescription(record['cp']),
              ),
              _buildTableRow(
                'Huyết áp nghỉ',
                record['trestbps'] != null
                    ? '${record['trestbps']} mmHg'
                    : 'N/A',
              ),
              _buildTableRow(
                'Cholesterol',
                record['chol'] != null ? '${record['chol']} mg/dL' : 'N/A',
              ),
              _buildTableRow(
                'Đường huyết đói',
                _getFbsDescription(record['fbs']),
              ),
              _buildTableRow(
                'Điện tâm đồ nghỉ',
                _getRestEcgDescription(record['restecg']),
              ),
              _buildTableRow(
                'Nhịp tim tối đa',
                record['thalach'] != null ? '${record['thalach']} bpm' : 'N/A',
              ),
              _buildTableRow(
                'Đau thắt ngực khi vận động',
                _getExangDescription(record['exang']),
              ),
              _buildTableRow(
                'ST Depression',
                record['oldpeak']?.toString() ?? 'N/A',
              ),
              _buildTableRow('Dốc ST', _getSlopeDescription(record['slope'])),
              _buildTableRow(
                'Số mạch máu chính',
                record['ca']?.toString() ?? 'N/A',
              ),
              _buildTableRow(
                'Thalassemia',
                _getThalDescription(record['thal']),
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
    if (dateTime == null) return 'Chưa có';

    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is Timestamp) {
        dt = dateTime.toDate();
      } else {
        return 'Chưa có';
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return 'Chưa có';
    }
  }

  // Helper methods for data description
  String _getChestPainDescription(dynamic cp) {
    if (cp == null) return 'N/A';
    const descriptions = {
      '0': 'Đau thắt ngực điển hình',
      '1': 'Đau thắt ngực không điển hình',
      '2': 'Đau không do thắt ngực',
      '3': 'Không triệu chứng',
    };
    return descriptions[cp.toString()] ?? cp.toString();
  }

  String _getFbsDescription(dynamic fbs) {
    if (fbs == null) return 'N/A';
    if (fbs.toString() == '1') return '> 120 mg/dL';
    if (fbs.toString() == '0') return '≤ 120 mg/dL';
    return fbs.toString();
  }

  String _getRestEcgDescription(dynamic restecg) {
    if (restecg == null) return 'N/A';
    const descriptions = {
      '0': 'Bình thường',
      '1': 'Bất thường ST-T',
      '2': 'Phì đại thất trái',
    };
    return descriptions[restecg.toString()] ?? restecg.toString();
  }

  String _getExangDescription(dynamic exang) {
    if (exang == null) return 'N/A';
    if (exang.toString() == '1') return 'Có';
    if (exang.toString() == '0') return 'Không';
    return exang.toString();
  }

  String _getSlopeDescription(dynamic slope) {
    if (slope == null) return 'N/A';
    const descriptions = {'0': 'Dốc lên', '1': 'Phẳng', '2': 'Dốc xuống'};
    return descriptions[slope.toString()] ?? slope.toString();
  }

  String _getThalDescription(dynamic thal) {
    if (thal == null) return 'N/A';
    const descriptions = {
      '1': 'Bình thường',
      '2': 'Khiếm khuyết cố định',
      '3': 'Khiếm khuyết có thể phục hồi',
    };
    return descriptions[thal.toString()] ?? thal.toString();
  }
}
