// lib/screens/doctor/diagnosis_result_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/screens/common/splash_screen.dart';
import 'package:dacn_app/screens/user/input_form_screen.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/widgets/app_theme.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final int prediction;
  final double probability;
  final Map<String, dynamic> inputData;
  final String language;
  final UserRole userRole;

  const DiagnosisResultScreen({
    Key? key,
    required this.prediction,
    required this.probability,
    required this.inputData,
    required this.language,
    required this.userRole,
  }) : super(key: key);

  @override
  _DiagnosisResultScreenState createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.userRole == UserRole.doctor ||
              widget.userRole == UserRole.nurse) &&
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
    if (phone == null && email == null) {
      setState(() => _isSaving = false);
      _showLoginError();
      return;
    }
    try {
      // query user doc
      final col = FirebaseFirestore.instance.collection('users');
      QuerySnapshot snap =
          phone != null
              ? await col.where('phone', isEqualTo: phone).limit(1).get()
              : await col.where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isEmpty) throw 'User not found';
      final uid = snap.docs.first.id;
      final record = {
        'timestamp': FieldValue.serverTimestamp(),
        'prediction': widget.prediction,
        'probability': widget.probability,
        'risk_level': widget.prediction == 1 ? 'high' : 'low',
        'risk_description':
            widget.language == 'vi'
                ? (widget.prediction == 1 ? 'Nguy cơ cao' : 'Nguy cơ thấp')
                : (widget.prediction == 1 ? 'High risk' : 'Low risk'),
        'input_data': widget.inputData,
      };
      await col.doc(uid).collection('health_records').add(record);
      await prefs.setBool('need_to_sync', true);
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
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

  void _showLoginError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.language == 'vi'
              ? 'Đăng nhập để lưu kết quả'
              : 'Please login to save',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = widget.prediction == 1;
    final tvi = widget.language == 'vi';
    final title =
        tvi
            ? (isHigh ? 'Nguy cơ cao' : 'Nguy cơ thấp')
            : (isHigh ? 'High Risk' : 'Low Risk');
    final probLabel = tvi ? 'Xác suất' : 'Probability';
    final saveText =
        _isSaved
            ? (tvi ? 'Đã lưu' : 'Saved')
            : (tvi ? 'Chưa lưu' : 'Not saved');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Kết quả đánh giá' : 'Result',
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_isSaved)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.cloud_done, color: AppColors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            // Risk Card
            Card(
              color: AppColors.cardBackground,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHigh ? Icons.warning : Icons.check_circle,
                          size: AppDimensions.iconXLarge,
                          color: isHigh ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: AppDimensions.paddingSmall),
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
                    const SizedBox(height: AppDimensions.marginSmall),
                    Text(
                      '$probLabel: \${(widget.probability*100).toStringAsFixed(2)}%',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.marginSmall),
                    Row(
                      children: [
                        Icon(
                          _isSaved ? Icons.cloud_done : Icons.cloud_queue,
                          color:
                              _isSaved ? AppColors.success : AppColors.textHint,
                          size: 16,
                        ),
                        const SizedBox(width: AppDimensions.paddingXSmall),
                        Text(saveText, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            // Input Details Card
            Card(
              color: AppColors.cardBackground,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tvi ? 'Chi tiết đầu vào' : 'Input Details',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    ...widget.inputData.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingXSmall,
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
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.marginLarge),
            // Recommended Actions
            if (isHigh)
              Card(
                color: AppColors.cardBackground,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tvi ? 'Giải pháp khuyến nghị' : 'Recommended Actions',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      ..._recommendations(tvi).map(
                        (sol) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingXSmall,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppDimensions.paddingSmall),
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
            const SizedBox(height: AppDimensions.marginLarge),
            // Buttons
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
                        style: AppTextStyles.buttonLarge,
                      ),
                      style: AppButtons.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          AppColors.success,
                        ),
                      ),
                    ),
                  ),
                if (!_isSaved &&
                    (widget.userRole == UserRole.doctor ||
                        widget.userRole == UserRole.nurse))
                  const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => InputFormScreen(language: widget.language, userRole: widget.userRole,),
                        ),
                      );
                    },
                    child: Text(
                      tvi ? 'Dự đoán lại' : 'Re-predict',
                      style: AppTextStyles.buttonLarge,
                    ),
                    style: AppButtons.primaryButtonStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _recommendations(bool tvi) {
    return tvi
        ? [
          'Tập thể dục nhẹ hàng ngày',
          'Hạn chế muối và chất béo',
          'Khám định kỳ 3 tháng',
          'Giữ tâm lý tích cực',
        ]
        : [
          'Light exercise daily',
          'Limit salt & fats',
          'Regular check-ups',
          'Maintain positive mindset',
        ];
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
            : ['None', 'Typical', 'Atypical', 'Severe'][v];
      default:
        return v.toString();
    }
  }
}
