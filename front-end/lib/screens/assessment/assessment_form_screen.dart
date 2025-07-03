// lib/screens/assessment/assessment_form_screen.dart
import 'package:dacn_app/screens/patients/patient_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/services/api/api_services.dart';
import 'package:dacn_app/screens/assessment/diagnosis_result_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/config/theme_config.dart';

/// Form nhập liệu và chọn bệnh nhân để đánh giá
class AssessmentFormScreen extends StatefulWidget {
  final String language;
  final UserRole userRole;

  const AssessmentFormScreen({
    Key? key,
    required this.language,
    required this.userRole,
  }) : super(key: key);

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<AssessmentFormScreen>
    with TickerProviderStateMixin {
  String? _selectedPatientId;
  bool _isLoading = false;
  late AnimationController _animationController;

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

  final Map<String, Map<String, String>> _labels = {
    'en': {
      'title': 'Cardiac Health Assessment',
      'instruction': 'Select patient and fill all fields',
      'patient': 'Select Patient',
      'submit': 'Predict Risk',
      'loading': 'Processing...',
      'fillAll': 'Please complete all fields',
      'selectPatient': 'Please select a patient',
      // Thêm labels cho các trường input
      'age': 'Age',
      'sex': 'Sex',
      'cp': 'Chest Pain Type',
      'trestbps': 'Resting Blood Pressure',
      'chol': 'Cholesterol Level',
      'fbs': 'Fasting Blood Sugar',
      'restecg': 'Resting ECG',
      'thalach': 'Maximum Heart Rate',
      'exang': 'Exercise Induced Angina',
      'oldpeak': 'ST Depression',
      'slope': 'Peak Exercise ST Slope',
      'ca': 'Number of Major Vessels',
      'thal': 'Thalassemia',
    },
    'vi': {
      'title': 'Đánh giá sức khỏe tim mạch',
      'instruction': 'Chọn bệnh nhân và nhập đầy đủ thông tin',
      'patient': 'Chọn bệnh nhân',
      'submit': 'Dự đoán',
      'loading': 'Đang xử lý...',
      'fillAll': 'Vui lòng điền hết mọi trường',
      'selectPatient': 'Vui lòng chọn bệnh nhân',
      // Thêm labels cho các trường input
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp nghỉ ngơi',
      'chol': 'Mức cholesterol',
      'fbs': 'Đường huyết lúc đói',
      'restecg': 'Điện tim nghỉ ngơi',
      'thalach': 'Nhịp tim tối đa',
      'exang': 'Đau thắt ngực do gắng sức',
      'oldpeak': 'Độ lệch ST',
      'slope': 'Độ dốc ST khi gắng sức',
      'ca': 'Số mạch máu lớn',
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

  Future<List<QueryDocumentSnapshot>> _fetchPatients() async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('patients')
              .orderBy('fullName')
              .get();
      return snap.docs;
    } catch (e) {
      print('Error fetching patients: $e');
      // Trả về danh sách rỗng nếu có lỗi
      return [];
    }
  }

  void _submitForm() async {
    final labels = _labels[widget.language]!;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(labels['selectPatient']!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
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
      final val =
          ['chol', 'oldpeak'].contains(k)
              ? double.tryParse(raw) ?? 0.0
              : int.tryParse(raw) ?? 0;
      return MapEntry(k, val);
    });
    final payload = {'patientId': _selectedPatientId, ...inputData};

    final result = await ApiService.predictHeartDisease(payload);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => DiagnosisResultScreen(
                patientId: _selectedPatientId!,
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

  Widget _buildPatientDropdown() {
    final labels = _labels[widget.language]!;
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchPatients(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snap.data ?? [];
        if (docs.isEmpty) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      widget.language == 'vi'
                          ? 'Chưa có bệnh nhân nào'
                          : 'No patients available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: AppButtonStyles.primary,
                onPressed: () {
                  // Điều hướng tới màn tạo bệnh nhân mới
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientFormScreen()),
                  );
                },
                child: Text(
                  widget.language == 'vi' ? 'Thêm bệnh nhân' : 'Add Patient',
                  style: AppTextStyles.button,
                ),
              ),
            ],
          );
        }
        return DropdownButtonFormField<String>(
          value: _selectedPatientId,
          decoration: InputDecoration(
            labelText: labels['patient'],
            hintText: labels['patient'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          items:
              docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(data['fullName'] ?? ''),
                );
              }).toList(),
          onChanged: (v) => setState(() => _selectedPatientId = v),
        );
      },
    );
  }

  Widget _buildField(String key) {
    final labels = _labels[widget.language]!;
    const categorical = {
      'sex': [0, 1],
      'cp': [0, 1, 2, 3],
      'restecg': [0, 1, 2],
      'exang': [0, 1],
      'slope': [0, 1, 2],
      'ca': [0, 1, 2, 3],
      'thal': [1, 2, 3],
    };

    // Debug: In ra label để kiểm tra
    print('Field $key - Label: ${labels[key]}');

    if (categorical.containsKey(key)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
        child: DropdownButtonFormField<int>(
          value: int.tryParse(controllers[key]!.text),
          decoration: InputDecoration(
            labelText: labels[key],
            hintText: labels[key],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          items:
              categorical[key]!.map((v) {
                var lbl = v.toString();
                if (key == 'sex') {
                  lbl =
                      widget.language == 'vi'
                          ? (v == 0 ? 'Nữ' : 'Nam')
                          : (v == 0 ? 'Female' : 'Male');
                }
                return DropdownMenuItem(value: v, child: Text(lbl));
              }).toList(),
          onChanged: (v) {
            if (v != null) controllers[key]!.text = v.toString();
            setState(() {});
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: TextField(
        controller: controllers[key],
        keyboardType:
            ['chol', 'oldpeak'].contains(key)
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: labels[key],
          hintText: labels[key],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels[widget.language]!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(labels['title']!, style: AppTextStyles.appBar),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              Card(
                color: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Text(
                    labels['instruction']!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.marginLarge),
              _buildPatientDropdown(),
              const SizedBox(height: AppSizes.marginMedium),
              // Hiển thị form input dù có hay không có bệnh nhân
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
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
        child: ElevatedButton(
          style: AppButtonStyles.primary,
          onPressed: _isLoading ? null : _submitForm,
          child: Text(
            _isLoading ? labels['loading']! : labels['submit']!,
            style: AppTextStyles.button,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
