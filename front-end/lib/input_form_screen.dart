import 'package:flutter/material.dart';
import 'package:dacn_app/main.dart';
import 'package:dacn_app/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputFormScreen extends StatefulWidget {
  final String language; // thêm tham số language

  const InputFormScreen({Key? key, required this.language}) : super(key: key);

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> controllers = {
    'age': TextEditingController(),
    'sex': TextEditingController(),
    'cp': TextEditingController(),
    'trestbps': TextEditingController(),
    'chol': TextEditingController(),
    'fbs': TextEditingController(),
    'restecg': TextEditingController(),
    'thalach': TextEditingController(),
    'exang': TextEditingController(),
    'oldpeak': TextEditingController(),
    'slope': TextEditingController(),
    'ca': TextEditingController(),
    'thal': TextEditingController(),
  };

  late AnimationController _animationController;
  bool _isLoading = false;

  // 2. Map chứa nhãn theo cả hai ngôn ngữ
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'title': 'Cardiac Health Assessment',
      'instruction':
          'Enter accurate information for the best prediction results',
      'submitLoading': 'Processing...',
      'submitButton': 'Predict Risk',
      'fillAll': 'Please fill in all fields',
      // Các nhãn form field
      'age': 'Age',
      'sex': 'Sex',
      'cp': 'Chest Pain Type',
      'trestbps': 'Resting BP (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Fasting Blood Sugar',
      'restecg': 'Rest ECG',
      'thalach': 'Max Heart Rate',
      'exang': 'Exercise Angina',
      'oldpeak': 'ST Depression',
      'slope': 'ST Slope',
      'ca': 'Major Vessels',
      'thal': 'Thalassemia',
    },
    'vi': {
      'title': 'Đánh giá sức khỏe tim mạch',
      'instruction': 'Nhập thông tin chính xác để có kết quả đánh giá tốt nhất',
      'submitLoading': 'Đang xử lý...',
      'submitButton': 'Dự đoán nguy cơ',
      'fillAll': 'Vui lòng điền đầy đủ thông tin',
      // Các nhãn form field
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp nghỉ (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Đường huyết lúc đói',
      'restecg': 'Điện tâm đồ nghỉ',
      'thalach': 'Nhịp tim tối đa (bpm)',
      'exang': 'Đau khi vận động',
      'oldpeak': 'Độ suy giảm ST',
      'slope': 'Độ dốc ST',
      'ca': 'Số lượng mạch chính',
      'thal': 'Thalassemia',
    },
  };

  final Map<String, Map<String, String>> _hints = {
    'en': {
      'age': 'Enter age (18-100)',
      'sex': '0 or 1',
      'cp': '0–3',
      'trestbps': 'e.g., 130',
      'chol': 'e.g., 250',
      'fbs': '0 or 1',
      'restecg': '0–2',
      'thalach': 'e.g., 180',
      'exang': '0 or 1',
      'oldpeak': 'e.g., 3.5',
      'slope': '0–2',
      'ca': '0–3',
      'thal': '1–3',
    },
    'vi': {
      'age': 'Nhập tuổi (18-100)',
      'sex': '0 hoặc 1',
      'cp': 'Từ 0 đến 3',
      'trestbps': 'Ví dụ: 130',
      'chol': 'Ví dụ: 250',
      'fbs': '0 hoặc 1',
      'restecg': 'Từ 0 đến 2',
      'thalach': 'Ví dụ: 180',
      'exang': '0 hoặc 1',
      'oldpeak': 'Ví dụ: 3.5',
      'slope': 'Từ 0 đến 2',
      'ca': 'Từ 0 đến 3',
      'thal': 'Từ 1 đến 3',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _submit() async {
    final labels = _labels[widget.language]!;
    // Kiểm tra xem đã điền đầy đủ chưa
    bool isValid = controllers.values.every(
      (controller) => controller.text.isNotEmpty,
    );

    if (!isValid) {
      _showCustomSnackBar(labels['fillAll']!, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Chuẩn hóa dữ liệu đầu vào
    final inputData = controllers.map((key, controller) {
      dynamic value;
      switch (key) {
        case 'age':
        case 'sex':
        case 'cp':
        case 'trestbps':
        case 'fbs':
        case 'restecg':
        case 'thalach':
        case 'exang':
        case 'slope':
        case 'ca':
        case 'thal':
          value = int.tryParse(controller.text) ?? 0;
          break;
        case 'chol':
        case 'oldpeak':
          value = double.tryParse(controller.text) ?? 0.0;
          break;
        default:
          value = controller.text;
      }
      return MapEntry(key, value);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      for (var entry in inputData.entries) {
        prefs.setString(entry.key, entry.value.toString());
      }
      prefs.setString('last_updated', DateTime.now().toIso8601String());

      // predictHeartDisease sẽ gọi lên server Flask, trả về Map {'prediction':..., 'probability':...}
      final result = await predictHeartDisease(inputData);

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => ResultScreen(
                  prediction: result['prediction'],
                  probability: result['probability'],
                  inputData: inputData,
                  language: widget.language,
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: child,
              );
            },
          ),
        );
      } else {
        _showCustomSnackBar(
          widget.language == 'en'
              ? 'Cannot predict. Please try again.'
              : 'Không thể dự đoán. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showCustomSnackBar(
        widget.language == 'en'
            ? 'An error occurred. Please try again.'
            : 'Đã xảy ra lỗi. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: isError ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[50] : Colors.green[50],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? Colors.red[200]! : Colors.green[200]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(String key, int index) {
    final labels = _labels[widget.language]!;
    final hints = _hints[widget.language]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề field
            Text(
              labels[key] ?? key,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            // Thông tin mô tả (nếu có)
            if (_getFieldDescription(key).isNotEmpty) ...[
              Text(
                _getFieldDescription(key),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 12),

            // TextField
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: controllers[key],
                keyboardType:
                    ['chol', 'oldpeak'].contains(key)
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hints[key] ?? '',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFieldDescription(String key) {
    final descriptionsVi = {
      'sex': '0: Nữ, 1: Nam',
      'cp': '0-3: Mức độ đau ngực',
      'fbs': '0: ≤120, 1: >120 mg/dL',
      'restecg': '0-2: Kết quả điện tâm đồ',
      'exang': '0: Không, 1: Có đau',
      'slope': '0-2: Độ dốc của ST',
      'ca': '0-3: Số mạch máu chính',
      'thal': '1-3: Loại Thalassemia',
    };
    final descriptionsEn = {
      'sex': '0: Female, 1: Male',
      'cp': '0–3: Chest pain type',
      'fbs': '0: ≤120, 1: >120 mg/dL',
      'restecg': '0–2: Resting ECG results',
      'exang': '0: No, 1: Yes',
      'slope': '0–2: ST slope',
      'ca': '0–3: Number of major vessels',
      'thal': '1–3: Thalassemia type',
    };
    return widget.language == 'vi'
        ? (descriptionsVi[key] ?? '')
        : (descriptionsEn[key] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[widget.language]!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          labels['title']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue[600],
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                labels['instruction']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...controllers.keys
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) => _buildInputCard(entry.value, entry.key))
                        .toList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _submit,
          backgroundColor: _isLoading ? Colors.grey[400] : Colors.blue[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label:
              _isLoading
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        labels['submitLoading']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    labels['submitButton']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
