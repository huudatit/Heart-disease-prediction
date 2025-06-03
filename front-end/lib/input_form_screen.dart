import 'package:flutter/material.dart';
import 'package:dacn_app/main.dart';
import 'package:dacn_app/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({Key? key}) : super(key: key);

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
    bool isValid = controllers.values.every(
      (controller) => controller.text.isNotEmpty,
    );

    if (!isValid) {
      _showCustomSnackBar('Vui lòng điền đầy đủ thông tin', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
          'Không thể dự đoán. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showCustomSnackBar('Đã xảy ra lỗi. Vui lòng thử lại.', isError: true);
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
            Text(
              _getLocalizedLabel(key),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (_getFieldDescription(key).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _getFieldDescription(key),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
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
                  hintText: _getLocalizedHint(key),
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
    final descriptions = {
      'sex': '0: Nữ, 1: Nam',
      'cp': '0-3: Mức độ đau ngực',
      'fbs': '0: ≤120, 1: >120 mg/dL',
      'restecg': '0-2: Kết quả điện tâm đồ',
      'exang': '0: Không, 1: Có đau',
      'slope': '0-2: Độ dốc của ST',
      'ca': '0-3: Số mạch máu chính',
      'thal': '1-3: Loại Thalassemia',
    };
    return descriptions[key] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Đánh giá sức khỏe tim mạch',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
              child: const Text(
                'Nhập thông tin chính xác để có kết quả đánh giá tốt nhất',
                style: TextStyle(
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
                  ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Đang xử lý...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  : const Text(
                    'Dự đoán nguy cơ',
                    style: TextStyle(
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

  String _getLocalizedLabel(String key) {
    final labels = {
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
    };
    return labels[key] ?? key;
  }

  String _getLocalizedHint(String key) {
    final hints = {
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
    };
    return hints[key] ?? 'Nhập giá trị';
  }
}
