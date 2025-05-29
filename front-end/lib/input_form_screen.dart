import 'package:flutter/material.dart';
import 'package:dacn_app/main.dart';
import 'package:dacn_app/result_screen.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({Key? key}) : super(key: key);

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
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

  void _submit() async {
    // Validate input
    bool isValid = controllers.values.every(
      (controller) => controller.text.isNotEmpty,
    );

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    // Convert input to correct data types
    final inputData = controllers.map((key, controller) {
      // Convert to appropriate data type based on the key
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

    final result = await predictHeartDisease(inputData);

    if (result != null) {
      // Navigate to ResultScreen with prediction data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ResultScreen(
                prediction: result['prediction'],
                probability: result['probability'],
                inputData: inputData,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể dự đoán. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập thông tin sức khỏe'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              controllers.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[key],
                    keyboardType:
                        ['chol', 'oldpeak'].contains(key)
                            ? TextInputType.numberWithOptions(decimal: true)
                            : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _getLocalizedLabel(key),
                      hintText: _getLocalizedHint(key),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        backgroundColor: Colors.blue[800],
        label: const Text('Dự đoán'),
        icon: const Icon(Icons.health_and_safety),
      ),
    );
  }

  // Localized labels for input fields
  String _getLocalizedLabel(String key) {
    final labels = {
      'age': 'Tuổi',
      'sex': 'Giới tính (0: Nữ, 1: Nam)',
      'cp': 'Loại đau ngực (0-3)',
      'trestbps': 'Huyết áp nghỉ (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Đường huyết lúc đói (0: <= 120, 1: > 120)',
      'restecg': 'Điện tâm đồ nghỉ (0-2)',
      'thalach': 'Nhịp tim tối đa',
      'exang': 'Đau khi vận động (0: Không, 1: Có)',
      'oldpeak': 'Độ suy giảm ST',
      'slope': 'Độ dốc ST (0-2)',
      'ca': 'Số lượng mạch chính (0-3)',
      'thal': 'Thalassemia (1-3)',
    };
    return labels[key] ?? key;
  }

  // Localized hints for input fields
  String _getLocalizedHint(String key) {
    final hints = {
      'age': 'Nhập tuổi',
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
