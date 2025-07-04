// /lib/screens/assessment/diagnosis_result_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dacn_app/screens/assessment/risk_recommendations.dart';
import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/config/theme_config.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final String patientId;
  final int prediction;
  final double probability;
  final Map<String, dynamic> inputData;
  final String language;
  final UserRole userRole;
  final bool isSaved;

  const DiagnosisResultScreen({
    super.key,
    required this.patientId,
    required this.prediction,
    required this.probability,
    required this.inputData,
    required this.language,
    required this.userRole,
    this.isSaved = true,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DiagnosisResultScreenState createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.isSaved &&
              (widget.userRole == UserRole.doctor ||
                  widget.userRole == UserRole.nurse)) &&
          !_isSaved) {
        _saveHealthRecord();
      }
    });
  }

  Future<void> _saveHealthRecord() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    final email = prefs.getString('email');
    final prob = widget.probability;
    final riskLevel = prob < 0.5 ? 'low' : (prob < 0.85 ? 'medium' : 'high');

    try {
      final col = FirebaseFirestore.instance.collection('patients');
      final snap =
          phone != null
              ? await col.where('phone', isEqualTo: phone).limit(1).get()
              : await col.where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isEmpty) throw 'User not found';
      final uid = snap.docs.first.id;
      final record = {
        'timestamp': FieldValue.serverTimestamp(),
        'prediction': widget.prediction,
        'probability': widget.probability,
        'risk_level': riskLevel,
        'risk_description':
            widget.language == 'vi'
                ? (widget.prediction == 1 ? 'Nguy cơ cao' : 'Nguy cơ thấp')
                : (widget.prediction == 1 ? 'High risk' : 'Low risk'),
        'input_data': {
          'fullName': widget.inputData['fullName'] ?? '—',
          'phone': phone ?? '—',
          ...widget.inputData,
        },
      };
      await col.doc(uid).collection('health_records').add(record);
      await prefs.setBool('need_to_sync', true);
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'vi' ? 'Đã lưu kết quả!' : 'Result saved!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'vi' ? 'Lỗi khi lưu: \$e' : 'Save error: \$e',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính riskLevel dựa trên xác suất
    final prob = widget.probability;
    final riskLevel = prob < 0.50 ? 'low' : (prob < 0.85 ? 'medium' : 'high');

    // 2. Tạo các biến phụ trợ
    final isHigh = riskLevel == 'high';
    final isMedium = riskLevel == 'medium';
    //final isLow = riskLevel == 'low';
    final tvi = widget.language == 'vi';

    // 3. Tiêu đề hiển thị (3 mức)
    String title;
    if (riskLevel == 'high') {
      title = tvi ? 'Nguy cơ cao' : 'High Risk';
    } else if (riskLevel == 'medium') {
      title = tvi ? 'Nguy cơ trung bình' : 'Medium Risk';
    } else {
      title = tvi ? 'Nguy cơ thấp' : 'Low Risk';
    }

    final probLabel = tvi ? 'Xác suất' : 'Probability';
    final saveText =
        _isSaved
            ? (tvi ? 'Đã lưu' : 'Saved')
            : (tvi ? 'Chưa lưu' : 'Not saved');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(title, style: AppTextStyles.appBar),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              child: SizedBox(
                width: AppSizes.iconMedium,
                height: AppSizes.iconMedium,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
            )
          else if (_isSaved)
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingSmall),
              child: const Icon(Icons.cloud_done, color: AppColors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            // 4. Card hiển thị mức độ
            Card(
              color: AppColors.cardBackground,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHigh ? Icons.warning : Icons.check_circle,
                          size: AppSizes.iconLarge,
                          color: isHigh ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.h3.copyWith(
                              color:
                                  isHigh ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.marginSmall),
                    Text(
                      '$probLabel: ${(prob * 100).toStringAsFixed(2)}%',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginSmall),
                    Row(
                      children: [
                        Icon(
                          _isSaved ? Icons.cloud_done : Icons.cloud_queue,
                          size: AppSizes.iconSmall,
                          color:
                              _isSaved ? AppColors.success : AppColors.textHint,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(saveText, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.marginLarge),

            // 5. Card chi tiết đầu vào (giữ nguyên)
            Card(
              color: AppColors.cardBackground,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tvi ? 'Chi tiết đầu vào' : 'Input Details',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    ...widget.inputData.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingSmall,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _label(e.key),
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              _format(e.key, e.value),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.marginLarge),

            // 6. Recommended Actions: bạn có thể hiện cả với mức medium nếu muốn
            if (isHigh || isMedium)
              Card(
                color: AppColors.cardBackground,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tvi ? 'Giải pháp khuyến nghị' : 'Recommended Actions',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      // I wanna use recommendations of assessment/risk_recommendations.dart
                      ...RiskRecommendations.getRecommendations(
                        riskLevel,
                        widget.language,
                      ).map(
                        (sol) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingSmall,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Expanded(
                                child: Text(
                                  sol,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSizes.marginLarge),

            // 7. Nút Save / Re-predict (giữ nguyên)
            Row(
              children: [
                if (!_isSaved &&
                    (widget.userRole == UserRole.doctor ||
                        widget.userRole == UserRole.nurse))
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
                                  color: AppColors.white,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: Text(
                        tvi ? 'Lưu kết quả' : 'Save Result',
                        style: AppTextStyles.button,
                      ),
                      style: AppButtonStyles.primary,
                    ),
                  ),
                if (!_isSaved &&
                    (widget.userRole == UserRole.doctor ||
                        widget.userRole == UserRole.nurse))
                  const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AssessmentFormScreen(
                                  language: widget.language,
                                  userRole: widget.userRole,
                                ),
                          ),
                        ),
                    style: AppButtonStyles.primary,
                    child: Text(
                      tvi ? 'Dự đoán lại' : 'Re-predict',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(String key) {
    const vi = {
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp',
      'chol': 'Cholesterol',
      'fbs': 'Đường',
      'restecg': 'ECG',
      'thalach': 'Nhịp tim',
      'exang': 'Đau vận động',
      'oldpeak': 'Giảm ST',
      'slope': 'Dốc ST',
      'ca': 'Mạch chính',
      'thal': 'Thal',
    };
    const en = {
      'age': 'Age',
      'sex': 'Sex',
      'cp': 'Chest Pain',
      'trestbps': 'Rest BP',
      'chol': 'Cholesterol',
      'fbs': 'Fasting BS',
      'restecg': 'Rest ECG',
      'thalach': 'Max HR',
      'exang': 'Exercise Angina',
      'oldpeak': 'ST Depress',
      'slope': 'ST Slope',
      'ca': 'Vessels',
      'thal': 'Thal',
    };
    return widget.language == 'vi' ? vi[key]! : en[key]!;
  }

  String _format(String key, dynamic v) {
    if (v == null) return '-';
    switch (key) {
      case 'sex':
        return widget.language == 'vi'
            ? (v == 1 ? 'Nam' : 'Nữ')
            : (v == 1 ? 'Male' : 'Female');
      case 'cp':
        return widget.language == 'vi'
            ? [
              'Không đau',
              'Đau thông thường',
              'Đau không điển hình',
              'Đau dữ dội',
            ][v]
            : ['0', '1', '2', '3'][v];
      default:
        return v.toString();
    }
  }
}
