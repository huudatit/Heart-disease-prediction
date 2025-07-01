// lib/screens/doctor/input_form_screen.dart

import 'package:flutter/material.dart';
import 'package:dacn_app/services/api/api_services.dart';

import 'package:dacn_app/screens/user/diagnosis_result_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/widgets/app_theme.dart';

class InputFormScreen extends StatefulWidget {
  final String language;
  final UserRole userRole; // thêm userRole để phân biệt doctor/nurse

  const InputFormScreen({
    Key? key,
    required this.language,
    required this.userRole,
  }) : super(key: key);

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

  final Map<String, Map<String, String>> _labels = {
    'en': {
      'title': 'Cardiac Health Assessment',
      'instruction': 'Fill all fields for accurate prediction',
      'submit': 'Predict Risk',
      'loading': 'Processing...',
      'fillAll': 'Please complete all fields',
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
      'instruction': 'Nhập đủ thông tin để dự đoán chính xác',
      'submit': 'Dự đoán',
      'loading': 'Đang xử lý...',
      'fillAll': 'Vui lòng điền hết mọi trường',
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp nghỉ (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Đường huyết lúc đói',
      'restecg': 'ECG nghỉ',
      'thalach': 'Nhịp tim tối đa',
      'exang': 'Đau khi gắng sức',
      'oldpeak': 'Giảm ST',
      'slope': 'Độ dốc ST',
      'ca': 'Số mạch chính',
      'thal': 'Thalassemia',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _submitForm() async {
    final labels = _labels[widget.language]!;
    if (controllers.values.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(labels['fillAll']!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final inputData = controllers.map((k, ctrl) {
      final raw = ctrl.text;
      dynamic val;
      if (['chol', 'oldpeak'].contains(k)) {
        val = double.tryParse(raw) ?? 0.0;
      } else {
        val = int.tryParse(raw) ?? 0;
      }
      return MapEntry(k, val);
    });

    final result = await ApiService.predictHeartDisease(inputData);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => DiagnosisResultScreen(
                prediction: result['prediction'] as int,
                probability: result['probability'] as double,
                inputData: inputData,
                language: widget.language,
                userRole: widget.userRole,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'vi' ? 'Lỗi khi dự đoán' : 'Error predicting',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildField(String key) {
    final labels = _labels[widget.language]!;

    // Các trường categorical (0–3, 0–1…)
    const categoricalOptions = {
      'sex': [0, 1],
      'cp': [0, 1, 2, 3],
      'restecg': [0, 1, 2],
      'exang': [0, 1],
      'slope': [0, 1, 2],
      'ca': [0, 1, 2, 3],
      'thal': [1, 2, 3],
    };

    final baseDecoration = InputDecoration(
      labelText: labels[key], // <-- đây là placeholder + label
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: AppColors.cardBackground, // trắng hoặc màu bạn muốn
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );

    if (categoricalOptions.containsKey(key)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
        child: DropdownButtonFormField<int>(
          value: int.tryParse(controllers[key]!.text),
          decoration: baseDecoration,
          dropdownColor: AppColors.cardBackground,
          elevation: 2,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          items:
              categoricalOptions[key]!.map((v) {
                String label = v.toString();
                if (key == 'sex') {
                  label =
                      widget.language == 'vi'
                          ? (v == 0 ? 'Nữ' : 'Nam')
                          : (v == 0 ? 'Female' : 'Male');
                }
                return DropdownMenuItem(value: v, child: Text(label));
              }).toList(),
          onChanged: (v) {
            if (v != null) controllers[key]!.text = v.toString();
            setState(() {});
          },
        ),
      );
    }

    // TextField cho các trường số
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: TextField(
        controller: controllers[key],
        keyboardType:
            ['chol', 'oldpeak'].contains(key)
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: labels[key], // <-- đây là placeholder + label
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: AppColors.cardBackground, // trắng hoặc màu bạn muốn
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[widget.language]!;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(labels['title']!, style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            children: [
              Card(
                color: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Text(
                    labels['instruction']!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.marginLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: controllers.keys.map(_buildField).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
        ),
        child: ElevatedButton(
          style: AppButtons.primaryButtonStyle,
          onPressed: _isLoading ? null : _submitForm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingSmall,
            ),
            child: Text(
              _isLoading ? labels['loading']! : labels['submit']!,
              style: AppTextStyles.buttonSmall,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
