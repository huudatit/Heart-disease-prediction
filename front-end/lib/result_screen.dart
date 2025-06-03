import 'package:flutter/material.dart';
import 'package:dacn_app/input_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultScreen extends StatefulWidget {
  final int prediction;
  final double probability;
  final Map<String, dynamic> inputData;

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.probability,
    required this.inputData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // Tự động lưu kết quả khi màn hình được tạo
    _saveHealthRecord();
  }

  Future<void> _saveHealthRecord() async {
    if (_isSaved) return; // Tránh lưu trùng lặp

    setState(() {
      _isSaving = true;
    });

    try {
      // Lấy thông tin user hiện tại
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Chuẩn bị dữ liệu để lưu
      final healthData = {
        'timestamp': FieldValue.serverTimestamp(),
        'prediction': widget.prediction,
        'probability': widget.probability,
        'risk_level': widget.prediction == 1 ? 'high' : 'low',
        'risk_description':
            widget.prediction == 1
                ? 'Nguy cơ mắc bệnh tim cao'
                : 'Nguy cơ mắc bệnh tim thấp',
        'input_data': widget.inputData,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user.uid,
      };

      // Lưu vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_records')
          .add(healthData);

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu kết quả thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu kết quả: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          "Kết quả đánh giá",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          // Hiển thị trạng thái lưu
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_isSaved)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.cloud_done, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Kết quả dự đoán
              Container(
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
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần kết luận
                    Row(
                      children: [
                        Icon(
                          widget.prediction == 1
                              ? Icons.warning_rounded
                              : Icons.check_circle_outline,
                          color:
                              widget.prediction == 1
                                  ? Colors.red[700]
                                  : Colors.green[700],
                          size: 40,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.prediction == 1
                                ? "Nguy cơ mắc bệnh tim cao"
                                : "Nguy cơ mắc bệnh tim thấp",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.prediction == 1
                                      ? Colors.red[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Xác suất
                    Text(
                      "Xác suất: ${(widget.probability * 100).toStringAsFixed(2)}%",
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                    ),

                    // Trạng thái lưu
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _isSaved ? Icons.cloud_done : Icons.cloud_queue,
                          size: 16,
                          color: _isSaved ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isSaving
                              ? "Đang lưu..."
                              : _isSaved
                              ? "Đã lưu vào hồ sơ"
                              : "Chưa lưu",
                          style: TextStyle(
                            fontSize: 14,
                            color: _isSaved ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Thông tin chi tiết đầu vào
              Container(
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
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chi tiết đầu vào",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...widget.inputData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLocalizedLabel(entry.key),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _transformValue(entry.key, entry.value),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Phần giải pháp
              widget.prediction == 1
                  ? Container(
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
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "💡 Các giải pháp khuyến nghị:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          "Tập thể dục nhẹ mỗi ngày",
                          "Hạn chế muối và chất béo",
                          "Khám định kỳ 3 tháng/lần",
                          "Duy trì tâm lý tích cực",
                        ].map(
                          (solution) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    solution,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox(),

              const SizedBox(height: 20),

              // Các nút hành động
              Row(
                children: [
                  // Nút lưu lại (nếu chưa lưu hoặc lưu thất bại)
                  if (!_isSaved)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveHealthRecord,
                        icon:
                            _isSaving
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Đang lưu...' : 'Lưu kết quả',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                  if (!_isSaved) const SizedBox(width: 10),

                  // Nút quay lại
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InputFormScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Dự đoán lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm chuyển đổi nhãn
  String _getLocalizedLabel(String key) {
    final labels = {
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp nghỉ (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Đường huyết lúc đói',
      'restecg': 'Điện tâm đồ nghỉ',
      'thalach': 'Nhịp tim tối đa',
      'exang': 'Đau khi vận động',
      'oldpeak': 'Độ suy giảm ST',
      'slope': 'Độ dốc ST',
      'ca': 'Số lượng mạch chính',
      'thal': 'Thalassemia',
    };
    return labels[key] ?? key;
  }

  // Hàm chuyển đổi giá trị
  String _transformValue(String key, dynamic value) {
    switch (key) {
      case 'sex':
        return value == 1 ? 'Nam' : 'Nữ';
      case 'cp':
        final cpLabels = [
          'Không đau',
          'Đau thông thường',
          'Đau không điển hình',
          'Đau nghiêm trọng',
        ];
        return cpLabels[value] ?? value.toString();
      case 'fbs':
        return value == 1 ? 'Cao (> 120 mg/dL)' : 'Bình thường (≤ 120 mg/dL)';
      case 'restecg':
        final restecgLabels = [
          'Bình thường',
          'Bất thường',
          'Dấu hiệu điển hình',
        ];
        return restecgLabels[value] ?? value.toString();
      case 'exang':
        return value == 1 ? 'Có' : 'Không';
      case 'slope':
        final slopeLabels = ['Không bằng phẳng', 'Độ dốc đều', 'Độ dốc xuống'];
        return slopeLabels[value] ?? value.toString();
      case 'thal':
        final thalLabels = [
          '',
          'Bình thường',
          'Khuyết tật cố định',
          'Khuyết tật thuận nghịch',
        ];
        return thalLabels[value] ?? value.toString();
      default:
        return value.toString();
    }
  }
}
