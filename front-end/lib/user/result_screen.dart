import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dacn_app/user/input_form_screen.dart';
import '../common/login_screen.dart';

class ResultScreen extends StatefulWidget {
  final int prediction;
  final double probability;
  final Map<String, dynamic> inputData;
  final String language; // thêm tham số này

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.probability,
    required this.inputData,
    required this.language, // bắt buộc truyền từ bên ngoài
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveHealthRecord();
    });
  }

  Future<void> _saveHealthRecord() async {
    if (_isSaved) return;

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('phone');
    final savedEmail = prefs.getString('email');

    if (savedPhone == null && savedEmail == null) {
      setState(() {
        _isSaving = false;
      });
      _showNotLoggedInError();
      return;
    }

    try {
      QuerySnapshot userQuery;
      if (savedPhone != null) {
        userQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: savedPhone)
                .get();
      } else {
        userQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: savedEmail)
                .get();
      }

      if (userQuery.docs.isEmpty) {
        setState(() {
          _isSaving = false;
        });
        _showNotLoggedInError();
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;

      final healthData = {
        'timestamp': FieldValue.serverTimestamp(),
        'prediction': widget.prediction,
        'probability': widget.probability,
        'risk_level': widget.prediction == 1 ? 'high' : 'low',
        'risk_description':
            widget.language == 'vi'
                ? (widget.prediction == 1 ? 'Nguy cơ cao' : 'Nguy cơ thấp')
                : (widget.prediction == 1 ? 'High risk' : 'Low risk'),
        'input_data': widget.inputData,
        'user_id': userId,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('health_records')
          .add(healthData);

      await prefs.setBool('need_to_sync', true);

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'vi'
                  ? 'Đã lưu kết quả thành công!'
                  : 'Successfully saved!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'vi'
                  ? 'Lỗi khi lưu kết quả: $e'
                  : 'Error saving result: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotLoggedInError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'vi'
                ? 'Vui lòng đăng nhập để lưu kết quả'
                : 'Please log in to save the result',
          ),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighRisk = widget.prediction == 1;
    final String titleText =
        isHighRisk
            ? (widget.language == 'vi'
                ? "Nguy cơ mắc bệnh tim cao"
                : "High Cardiovascular Risk")
            : (widget.language == 'vi'
                ? "Nguy cơ mắc bệnh tim thấp"
                : "Low Cardiovascular Risk");
    final String probabilityLabel =
        widget.language == 'vi' ? "Xác suất" : "Probability";
    final String savedStatus =
        _isSaving
            ? (widget.language == 'vi' ? "Đang lưu..." : "Saving...")
            : _isSaved
            ? (widget.language == 'vi'
                ? "Đã lưu vào hồ sơ"
                : "Saved to profile")
            : (widget.language == 'vi' ? "Chưa lưu" : "Not saved");

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          widget.language == 'vi' ? "Kết quả đánh giá" : "Result",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
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
              // ---------- Phần hiển thị kết quả ----------
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
                    // Icon + Text
                    Row(
                      children: [
                        Icon(
                          isHighRisk
                              ? Icons.warning_rounded
                              : Icons.check_circle_outline,
                          color:
                              isHighRisk ? Colors.red[700] : Colors.green[700],
                          size: 40,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isHighRisk
                                      ? Colors.red[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Xác suất / Probability
                    Text(
                      "$probabilityLabel: ${(widget.probability * 100).toStringAsFixed(2)}%",
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                    ),
                    const SizedBox(height: 10),
                    // Trạng thái lưu / status
                    Row(
                      children: [
                        Icon(
                          _isSaved ? Icons.cloud_done : Icons.cloud_queue,
                          size: 16,
                          color: _isSaved ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          savedStatus,
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
              // ---------- Chi tiết đầu vào / Input details ----------
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
                      widget.language == 'vi'
                          ? "Chi tiết đầu vào"
                          : "Input Details",
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
              // ---------- Gợi ý nếu nguy cơ cao ----------
              if (widget.prediction == 1)
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
                        widget.language == 'vi'
                            ? "💡 Các giải pháp khuyến nghị:"
                            : "💡 Recommended Actions:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 15),
                      ...[
                        widget.language == 'vi'
                            ? "Tập thể dục nhẹ mỗi ngày"
                            : "Light exercise daily",
                        widget.language == 'vi'
                            ? "Hạn chế muối và chất béo"
                            : "Limit salt and fats",
                        widget.language == 'vi'
                            ? "Khám định kỳ 3 tháng/lần"
                            : "Regular check‐ups every 3 months",
                        widget.language == 'vi'
                            ? "Duy trì tâm lý tích cực"
                            : "Maintain a positive mindset",
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
                ),

              const SizedBox(height: 20),
              // ---------- Nút hành động / Buttons ----------
              Row(
                children: [
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
                          _isSaving
                              ? (widget.language == 'vi'
                                  ? 'Đang lưu...'
                                  : 'Saving...')
                              : (widget.language == 'vi'
                                  ? 'Lưu kết quả'
                                  : 'Save Result'),
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Khi bấm “Dự đoán lại”/“Re–predict”, truyền lại language hiện tại
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    InputFormScreen(language: widget.language),
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
                      child: Text(
                        widget.language == 'vi' ? 'Dự đoán lại' : 'Re–predict',
                        style: const TextStyle(
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

  /// Biên dịch từ key sang nhãn hiển thị
  String _getLocalizedLabel(String key) {
    final labelsVi = {
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
    final labelsEn = {
      'age': 'Age',
      'sex': 'Sex',
      'cp': 'Chest Pain Type',
      'trestbps': 'Resting BP (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Fasting Blood Sugar',
      'restecg': 'Resting ECG',
      'thalach': 'Max Heart Rate',
      'exang': 'Exercise Angina',
      'oldpeak': 'ST Depression',
      'slope': 'ST Slope',
      'ca': 'Major Vessels',
      'thal': 'Thalassemia',
    };
    return widget.language == 'vi'
        ? (labelsVi[key] ?? key)
        : (labelsEn[key] ?? key);
  }

  /// Biên dịch giá trị theo từng trường, tương tự _transformValue cũ
  String _transformValue(String key, dynamic value) {
    if (value == null) return 'N/A';
    switch (key) {
      case 'sex':
        return widget.language == 'vi'
            ? (value == 1 ? 'Nam' : 'Nữ')
            : (value == 1 ? 'Male' : 'Female');
      case 'cp':
        final cpLabelsVi = [
          'Không đau',
          'Đau thông thường',
          'Đau không điển hình',
          'Đau nghiêm trọng',
        ];
        final cpLabelsEn = [
          'None',
          'Typical angina',
          'Atypical angina',
          'Non-anginal pain',
        ];
        return widget.language == 'vi'
            ? cpLabelsVi[value] ?? value.toString()
            : cpLabelsEn[value] ?? value.toString();
      case 'fbs':
        return widget.language == 'vi'
            ? (value == 1 ? 'Cao (> 120 mg/dL)' : 'Bình thường (≤ 120 mg/dL)')
            : (value == 1 ? 'High (> 120 mg/dL)' : 'Normal (≤ 120 mg/dL)');
      case 'restecg':
        final vi = ['Bình thường', 'Bất thường ST-T', 'Phì đại thất trái'];
        final en = [
          'Normal',
          'ST-T abnormality',
          'Left ventricular hypertrophy',
        ];
        return widget.language == 'vi'
            ? vi[value] ?? value.toString()
            : en[value] ?? value.toString();
      case 'exang':
        return widget.language == 'vi'
            ? (value == 1 ? 'Có' : 'Không')
            : (value == 1 ? 'Yes' : 'No');
      case 'slope':
        final vi = ['Dốc lên', 'Phẳng', 'Dốc xuống'];
        final en = ['Upsloping', 'Flat', 'Downsloping'];
        return widget.language == 'vi'
            ? vi[value] ?? value.toString()
            : en[value] ?? value.toString();
      case 'thal':
        final vi = [
          '',
          'Bình thường',
          'Khuyết tật cố định',
          'Khuyết tật thuận nghịch',
        ];
        final en = ['', 'Normal', 'Fixed defect', 'Reversible defect'];
        return widget.language == 'vi'
            ? vi[value] ?? value.toString()
            : en[value] ?? value.toString();
      default:
        return value.toString();
    }
  }
}
