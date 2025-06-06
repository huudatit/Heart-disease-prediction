import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'input_form_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key, this.language = 'en'}) : super(key: key);
  final String language;

  @override
  Widget build(BuildContext context) {
    final infoList = {
      'vi': [
        {
          'label': 'Tuổi',
          'desc':
              '< 45: thấp; 45–54: trung bình; ≥ 55: cao. Tuổi càng cao, nguy cơ tim mạch càng tăng.',
          'action':
              'Thực hiện kiểm tra định kỳ hàng năm, duy trì lối sống lành mạnh.',
        },
        {
          'label': 'Giới tính',
          'desc':
              'Nam giới: nguy cơ cao hơn nữ giới ở cùng độ tuổi. Sau mãn kinh, nguy cơ của phụ nữ tăng lên.',
          'action':
              'Nam giới > 45 tuổi nên kiểm tra ECG/Cholesterol, phụ nữ sau mãn kinh nên chú ý sức khỏe tim mạch.',
        },
        {
          'label': 'Đau ngực (CP)',
          'desc':
              '0 = Không triệu chứng; 1 = Đau điển hình; 2 = Đau không điển hình; 3 = Đau không do tim.',
          'action':
              'Nếu CP = 1 hoặc 2, cân nhắc làm nghiệm pháp gắng sức hoặc siêu âm tim để đánh giá thêm.',
        },
        {
          'label': 'Huyết áp nghỉ',
          'desc':
              '< 120/80 mmHg: bình thường\n120–129/80–84 mmHg: tiền cao huyết áp\n≥ 140/90 mmHg: cao',
          'action':
              'Nếu ≥ 120/80, giảm muối, tập thể dục; ≥ 140/90 cần điều trị theo hướng dẫn bác sĩ.',
        },
        {
          'label': 'Cholesterol',
          'desc':
              '< 200 mg/dL: bình thường\n200–239 mg/dL: gần ngưỡng cao\n≥ 240 mg/dL: cao',
          'action':
              'Giảm chất béo bão hòa, tăng chất xơ; kiểm tra lipid toàn phần 6–12 tháng/lần.',
        },
        {
          'label': 'Đường huyết lúc đói',
          'desc':
              '< 100 mg/dL: bình thường\n100–125 mg/dL: tiền tiểu đường\n≥ 126 mg/dL: nghi ngờ tiểu đường',
          'action':
              'Hạn chế đường, tập thể dục đều; kiểm tra HbA1c khi ≥ 100 mg/dL.',
        },
        {
          'label': 'Điện tâm đồ nghỉ (RESTECG)',
          'desc':
              '0 = Bình thường\n1 = Bất thường ST-T (ST/T deviation)\n2 = Phì đại thất trái (LVH)',
          'action':
              'Nếu ≥ 1, cân nhắc siêu âm tim hoặc thử nghiệm gắng sức để đánh giá chức năng tim.',
        },
        {
          'label': 'Nhịp tim tối đa (Thalach)',
          'desc':
              '< 100 bpm khi gắng sức: có thể bất thường; ≥ 100 bpm: bình thường.',
          'action':
              'Nếu thấp bất thường khi gắng sức, nên đo Holter hoặc thử nghiệm gắng sức.',
        },
        {
          'label': 'Đau khi vận động (Exang)',
          'desc': '0 = Không; 1 = Có.\nNếu có, tăng nguy cơ bệnh mạch vành.',
          'action':
              'Nếu = 1, đi kiểm tra chuyên khoa tim mạch, làm nghiệm pháp gắng sức.',
        },
        {
          'label': 'ST giảm (Oldpeak)',
          'desc':
              '< 1 mm: bình thường\n1–2 mm: nhẹ\n> 2 mm: cảnh báo thiếu máu cơ tim khi gắng sức',
          'action':
              'Nếu > 1 mm, cần làm ECG gắng sức hoặc chụp mạch vành nếu nghi ngờ cao.',
        },
        {
          'label': 'Độ dốc ST (Slope)',
          'desc':
              '0 = Bậc lên (Upsloping) – tốt nhất\n1 = Bằng phẳng (Flat) – trung bình\n2 = Dốc xuống (Downsloping) – cảnh báo',
          'action':
              'Nếu = 2, nguy cơ tim mạch cao, thực hiện khảo sát mạch vành/siêu âm tim.',
        },
        {
          'label': 'Số mạch chính (CA)',
          'desc':
              '0: Không hẹp\n1: 1 động mạch\x0a2: 2 động mạch\n3: 3 động mạch\nSố càng cao → nguy cơ càng lớn.',
          'action':
              'Nếu ≥ 1, cân nhắc chụp CT mạch vành hoặc chụp động mạch vành xâm lấn.',
        },
        {
          'label': 'Thalassemia (Thal)',
          'desc':
              '1 = Bình thường\n2 = Khiếm khuyết cố định\n3 = Khiếm khuyết thuận nghịch\n6 hoặc 7 (giá trị đặc biệt) liên quan đến lưu thông máu bất thường.',
          'action':
              'Nếu = 2 hoặc 3, tham khảo kết quả siêu âm tim/CT mạch vành để đánh giá thêm.',
        },
      ],
      'en': [
        {
          'label': 'Age',
          'desc':
              '< 45: low risk; 45–54: moderate risk; ≥ 55: high risk. Higher age → higher CAD risk.',
          'action':
              'Annual check-up; maintain healthy lifestyle with balanced diet and exercise.',
        },
        {
          'label': 'Sex',
          'desc':
              'Male: higher risk than female at same age. Post‐menopause women risk increases.',
          'action':
              'Men over 45 should screen LDL/HbA1c; post‐menopause women monitor blood pressure & lipids.',
        },
        {
          'label': 'Chest Pain (CP)',
          'desc':
              '0 = Asymptomatic\n1 = Typical angina\n2 = Atypical angina\n3 = Non‐anginal pain.',
          'action':
              'If CP = 1 or 2, consider stress ECG or echocardiogram for further evaluation.',
        },
        {
          'label': 'Resting BP',
          'desc':
              '< 120/80 mmHg: normal\n120–129/80–84 mmHg: elevated\n≥ 140/90 mmHg: high',
          'action':
              'If ≥ 120/80, reduce salt, exercise; if ≥ 140/90, follow physician for medication.',
        },
        {
          'label': 'Cholesterol',
          'desc':
              '< 200 mg/dL: desirable\n200–239 mg/dL: borderline high\n≥ 240 mg/dL: high',
          'action':
              'Reduce saturated fats, increase fiber; repeat lipid panel every 6–12 months.',
        },
        {
          'label': 'Fasting Blood Sugar (FBS)',
          'desc':
              '< 100 mg/dL: normal\n100–125 mg/dL: prediabetes\n≥ 126 mg/dL: diabetic range',
          'action':
              'Limit simple sugars, exercise daily; check HbA1c if ≥ 100 mg/dL.',
        },
        {
          'label': 'Rest ECG (RESTECG)',
          'desc':
              '0 = Normal\n1 = ST-T abnormality\n2 = Left ventricular hypertrophy (LVH)',
          'action':
              'If ≥ 1, consider echocardiogram or stress test to evaluate cardiac function.',
        },
        {
          'label': 'Max Heart Rate (Thalach)',
          'desc':
              '< 100 bpm under stress: may be abnormal; ≥ 100 bpm: expected.',
          'action':
              'If unusually low under exertion, perform Holter monitoring or stress test.',
        },
        {
          'label': 'Exercise Angina (Exang)',
          'desc': '0 = No; 1 = Yes. Presence indicates higher CAD risk.',
          'action': 'If = 1, refer for cardiology consult and stress testing.',
        },
        {
          'label': 'ST Depression (Oldpeak)',
          'desc':
              '< 1 mm: normal\n1–2 mm: mild depression\n> 2 mm: indicates ischemia during exercise',
          'action':
              'If > 1 mm, perform stress ECG or coronary angiography if high suspicion.',
        },
        {
          'label': 'ST Slope (Slope)',
          'desc':
              '0 = Upsloping (best prognostic)\n1 = Flat (moderate)\n2 = Downsloping (worrisome)',
          'action':
              'If = 2, high risk; consider invasive angiography or advanced imaging.',
        },
        {
          'label': 'Major Vessels (CA)',
          'desc':
              '0 = none blocked\n1 = 1 vessel\n2 = 2 vessels\n3 = 3 vessels. Higher count → higher risk.',
          'action':
              'If ≥ 1, consider coronary CT or invasive coronary angiogram.',
        },
        {
          'label': 'Thalassemia (Thal)',
          'desc':
              '1 = Normal\n2 = Fixed defect\n3 = Reversible defect\nValues 6 or 7 suggest severe perfusion abnormalities.',
          'action':
              'If = 2 or 3, correlate with imaging (echo/CT) to assess myocardial perfusion.',
        },
      ],
    };

    final selectedList = infoList[language]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          language == 'vi'
              ? 'Thông tin chỉ số & đánh giá'
              : 'Metric Details & Risk Assessment',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: selectedList.length,
              itemBuilder: (context, index) {
                final item = selectedList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        color: Colors.blue[800],
                        size: 30,
                      ),
                    ),
                    title: Text(
                      item['label']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item['desc']!,
                          style: const TextStyle(height: 1.5, fontSize: 15),
                        ),
                        if (item.containsKey('action')) ...[
                          const SizedBox(height: 6),
                          Text(
                            language == 'vi'
                                ? 'Khuyến nghị: ${item['action']}'
                                : 'Recommendation: ${item['action']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                // Khi bấm vào, chuyển qua màn InputForm với truyền ngôn ngữ
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InputFormScreen(language: language),
                  ),
                );

                if (result != null) {
                  final prefs = await SharedPreferences.getInstance();
                  result.forEach((key, value) {
                    prefs.setString(key, value.toString());
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                language == 'vi' ? "Nhập thông tin" : "Enter Information",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
