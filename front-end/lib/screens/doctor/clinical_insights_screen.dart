// lib/screens/home/doctor/clinical_insights_screen.dart
import 'package:flutter/material.dart';
import 'package:dacn_app/config/theme_config.dart';

/// Màn Thông Tin Lâm Sàng dành cho Bác sĩ
class ClinicalInsightsScreen extends StatefulWidget {
  final String language;
  const ClinicalInsightsScreen({super.key, required this.language});

  @override
  State<ClinicalInsightsScreen> createState() => _ClinicalInsightsScreenState();
}

class _ClinicalInsightsScreenState extends State<ClinicalInsightsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRisk = 'Thấp (<50%)';

  final List<String> _riskLevels = [
    'Thấp (<50%)',
    'Trung bình (50–85%)',
    'Cao (>85%)',
  ];

  final Map<String, List<String>> _recommendations = {
    'Thấp (<50%)': [
      'Duy trì lối sống lành mạnh: kiểm soát cân nặng, tránh ngồi nhiều, giữ tinh thần tích cực.',
      'Ăn uống cân bằng: nhiều rau xanh, trái cây, ngũ cốc nguyên hạt; giảm muối dưới 5g/ngày.',
      'Tập thể dục tối thiểu 150 phút/tuần (cường độ vừa phải).',
      'Tuyệt đối không hút thuốc và hạn chế rượu bia.',
      'Khám định kỳ 6–12 tháng: đo huyết áp, lipid máu, đường huyết.',
    ],
    'Trung bình (50–85%)': [
      'Điều chỉnh lối sống ngay: giảm ngồi nhiều, ngủ đủ giấc, duy trì BMI 18.5–24.9.',
      'Chế độ ăn ít muối (<5g/ngày), nhiều chất xơ.',
      '150 phút/tuần hoạt động vừa phải hoặc 75 phút cường độ cao.',
      'Ngừng hoàn toàn sử dụng thuốc lá.',
      'Quản lý chặt chẽ bệnh nền (tăng huyết áp, đái tháo đường).',
      'Giảm stress: thiền, hít thở sâu, yoga.',
    ],
    'Cao (>85%)': [
      'Chế độ ăn nghiêm ngặt: rau xanh, ngũ cốc nguyên hạt; muối <3g/ngày; tránh chất béo trans.',
      '150–300 phút/tuần hoạt động vừa phải hoặc 75–150 phút cường độ cao.',
      'Không hút thuốc, hạn chế rượu (≤1 đơn vị nữ, ≤2 đơn vị nam).',
      'Thư giãn hàng ngày: thiền, hít thở 4-7-8, yoga.',
      'Khám chuyên khoa tim mạch định kỳ 3–6 tháng: siêu âm, ECG, stress test.',
      'Tuân thủ điều trị: ACE inhibitors, beta-blockers, statin, aspirin theo chỉ định.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Thông Tin Lâm Sàng', style: AppTextStyles.appBar),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          // ignore: deprecated_member_use
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle: AppTextStyles.bodyMedium, // cài kiểu chữ chung
          unselectedLabelStyle:
              AppTextStyles.bodySmall, // cài kiểu chữ unselected
          tabs: const [Tab(text: 'Phân Tích'), Tab(text: 'Khuyến Nghị')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAnalysisTab(), _buildRecommendationsTab()],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Text(
                'Phân tích yếu tố nguy cơ...',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.marginMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Text(
                'Chỉ số sức khỏe cộng đồng...',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.marginMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Text(
                'Ma trận tương quan...',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.marginMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Text(
                'Xu hướng thời gian...',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildRecommendationsTab() {
    final tvi = widget.language == 'vi';
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tvi ? 'Chọn mức nguy cơ:' : 'Select risk level:',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSizes.paddingSmall),

          // 1) Bọc Dropdown trong Theme widget
          Theme(
            data: Theme.of(context).copyWith(
              dropdownMenuTheme: DropdownMenuThemeData(
                // 'menuStyle' là nơi cấu hình backgroundColor + shape
                menuStyle: MenuStyle(
                  // nền trắng cho popup
                  backgroundColor: WidgetStateProperty.all(AppColors.white),
                  // bo góc cho popup
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedRisk,
              isExpanded: true,
              dropdownColor: AppColors.white, // phòng ngừa
              decoration: InputDecoration(
                labelText: tvi ? 'Mức nguy cơ' : 'Risk Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              items:
                  _riskLevels
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
              onChanged: (v) => setState(() => _selectedRisk = v!),
            ),
          ),

          const SizedBox(height: AppSizes.marginMedium),

          Expanded(
            child: ListView.separated(
              separatorBuilder:
                  (_, _) => const SizedBox(height: AppSizes.marginSmall),
              itemCount: _recommendations[_selectedRisk]!.length,
              itemBuilder: (_, i) {
                final tip = _recommendations[_selectedRisk]![i];
                return Card(
                  color: AppColors.cardBackground,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(
                          child: Text(tip, style: AppTextStyles.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}