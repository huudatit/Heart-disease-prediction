// lib/screens/assessment/risk_recommendations.dart

import 'package:flutter/material.dart';
import 'package:dacn_app/config/theme_config.dart';

/// Widget hiển thị khuyến cáo theo mức độ nguy cơ tim mạch
class RiskRecommendations extends StatelessWidget {
  /// riskLevel: "low", "medium", "high"
  final String riskLevel;
  final String language; // 'en' hoặc 'vi'

  const RiskRecommendations({
    super.key,
    required this.riskLevel,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final isVi = language == 'vi';
    // Chọn danh sách khuyến cáo
    final List<String> recs = _getRecommendations(riskLevel, isVi);
    final title = isVi ? 'Khuyến cáo cho mức nguy cơ' : 'Recommendations';
    final subtitle = isVi ? _titleVi(riskLevel) : _titleEn(riskLevel);

    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.marginLarge),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title: $subtitle',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.marginMedium),
            ...recs.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r, style: AppTextStyles.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getRecommendations(String level, bool vi) {
    switch (level) {
      case 'low':
        return vi
            ? [
              'Duy trì lối sống lành mạnh: kiểm soát cân nặng, tránh ngồi nhiều, giữ tinh thần tích cực.',
              'Ăn uống theo chế độ Địa Trung Hải: nhiều rau xanh, trái cây, ngũ cốc nguyên hạt, hạn chế muối, đường và chất béo bão hòa.',
              '150 phút hoạt động thể lực vừa phải hoặc 75 phút cường độ cao mỗi tuần.',
              'Từ bỏ thuốc lá, hạn chế rượu bia.',
              'Khám tim mạch định kỳ 6–12 tháng, tự đo huyết áp tại nhà.',
            ]
            : [
              'Maintain healthy lifestyle: weight control, reduce sedentary behavior, positive mind.',
              'Follow Mediterranean diet: vegetables, fruits, whole grains; limit salt, sugar, saturated fats.',
              'At least 150 min moderate or 75 min vigorous exercise per week.',
              'Quit smoking and minimize alcohol intake.',
              'Routine cardiac check-up every 6–12 months; home BP monitoring.',
            ];
      case 'medium':
        return vi
            ? [
              'Điều chỉnh lối sống: giảm ngồi nhiều, ngủ đủ giấc, duy trì cân nặng.',
              'Chế độ ăn ít muối, giảm chất béo bão hòa và đường tinh luyện.',
              '150 phút/tuần hoạt động vừa phải hoặc 75 phút/tuần cường độ cao.',
              'Ngừng hoàn toàn nicotine và cai thuốc càng sớm càng tốt.',
              'Quản lý bệnh nền: huyết áp, lipid, đái tháo đường theo chỉ dẫn.',
              'Thư giãn, thiền, yoga để giảm căng thẳng; ngủ 7–8 giờ mỗi đêm.',
            ]
            : [
              'Adjust lifestyle: reduce sitting time, adequate sleep, healthy weight.',
              'Low-salt diet; cut saturated fats and refined sugar.',
              '150 min moderate or 75 min vigorous activity weekly.',
              'Complete nicotine cessation as soon as possible.',
              'Manage comorbidities: BP, lipids, diabetes under medical guidance.',
              'Stress control: meditation, yoga; ensure 7–8 hours of sleep.',
            ];
      case 'high':
        return vi
            ? [
              'Chế độ ăn nghiêm ngặt: ưu tiên rau củ, hạn chế muối dưới 3 g/ngày, không đường tinh luyện và chất béo trans.',
              'Duy trì 150–300 phút hoạt động vừa phải hoặc 75–150 phút cường độ cao mỗi tuần; 2 buổi kháng lực nhẹ.',
              'Tuyệt đối cai thuốc và hạn chế rượu nghiêm ngặt.',
              'Thiền, hít thở sâu 10–15 phút/ngày, tham vấn chuyên gia tâm lý khi cần.',
              'Khám tim mạch chuyên khoa: siêu âm, ECG, stress test; tái khám 3–6 tháng/lần.',
              'Tuân thủ phác đồ thuốc: ACE inhibitors, beta-blockers, statin, aspirin; theo dõi tác dụng phụ.',
            ]
            : [
              'Strict diet: vegetables, <3g salt/day, avoid refined sugar & trans fats.',
              '150–300 min moderate or 75–150 min vigorous exercise weekly; plus 2 light resistance sessions.',
              'Absolute smoking cessation and strict alcohol limitation.',
              'Daily mindfulness/ breathing (10–15 min); psychological support if needed.',
              'Specialist cardiology follow-up: echo, ECG, stress tests; re-evaluate every 3–6 months.',
              'Adhere to medication regimens: ACE inhibitors, beta-blockers, statins, aspirin; monitor side effects.',
            ];
      default:
        return [];
    }
  }

  String _titleVi(String lvl) {
    switch (lvl) {
      case 'low':
        return 'Nguy cơ thấp (<50%)';
      case 'medium':
        return 'Nguy cơ trung bình (50–85%)';
      case 'high':
        return 'Nguy cơ cao (>85%)';
      default:
        return '';
    }
  }

  String _titleEn(String lvl) {
    switch (lvl) {
      case 'low':
        return 'Low Risk (<50%)';
      case 'medium':
        return 'Medium Risk (50–85%)';
      case 'high':
        return 'High Risk (>85%)';
      default:
        return '';
    }
  }

  static List<String> getRecommendations(String lang, String level) {
    if (level == 'high') {
      return lang == 'vi'
          ? ['... khuyến nghị 1', '... khuyến nghị 2']
          : ['High rec 1', 'High rec 2'];
    } else if (level == 'medium') {
      // ...
      return [];
    } else {
      // ...
      return [];
    }
  }
}
