import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, this.language = 'en'});
  final String language;

  @override
  Widget build(BuildContext context) {
    final infoList = {
      'vi': [
        {
          'label': 'Tuổi',
          'desc':
              'Tuổi càng cao thì nguy cơ mắc bệnh tim càng lớn, đặc biệt > 50.',
        },
        {
          'label': 'Giới tính',
          'desc':
              'Nam giới thường có nguy cơ mắc bệnh tim cao hơn nữ giới ở cùng độ tuổi.',
        },
        {
          'label': 'Đau ngực',
          'desc':
              'Kiểu đau ngực dạng 4 (điển hình) có khả năng liên quan đến bệnh tim.',
        },
        {
          'label': 'Huyết áp nghỉ',
          'desc': 'Huyết áp > 140 mmHg là dấu hiệu cảnh báo bệnh tim.',
        },
        {
          'label': 'Cholesterol',
          'desc': 'Mức cholesterol > 240 mg/dL là cao, cần lưu ý đến tim mạch.',
        },
        {
          'label': 'Đường huyết lúc đói',
          'desc': '> 120 mg/dL: nguy cơ cao bị tiểu đường, ảnh hưởng đến tim.',
        },
        {
          'label': 'Điện tâm đồ',
          'desc': 'Giá trị bất thường có thể là dấu hiệu của bệnh lý tim mạch.',
        },
        {
          'label': 'Nhịp tim tối đa',
          'desc':
              'Nhịp tim tối đa thấp bất thường khi gắng sức là yếu tố nguy cơ.',
        },
        {
          'label': 'Đau khi vận động',
          'desc': 'Nếu có, nguy cơ mắc bệnh mạch vành cao hơn.',
        },
        {
          'label': 'ST giảm',
          'desc': '> 2 mm: dấu hiệu thiếu máu cơ tim khi gắng sức.',
        },
        {
          'label': 'Dốc ST',
          'desc': 'Giá trị bất thường có thể gợi ý nguy cơ bệnh tim.',
        },
        {
          'label': 'Số mạch chính',
          'desc': 'Số lượng mạch bị tắc càng cao, nguy cơ càng lớn.',
        },
        {
          'label': 'Thalassemia',
          'desc': 'Rối loạn tuần hoàn máu cơ tim nếu giá trị là 6 hoặc 7.',
        },
      ],
      'en': [
        {
          'label': 'Age',
          'desc':
              'Higher age increases the risk of heart disease, especially > 50.',
        },
        {
          'label': 'Sex',
          'desc':
              'Men are generally at higher risk than women at the same age.',
        },
        {
          'label': 'Chest Pain',
          'desc':
              'Type 4 (typical angina) is often associated with heart disease.',
        },
        {
          'label': 'Resting BP',
          'desc': 'BP > 140 mmHg is a risk indicator for heart disease.',
        },
        {
          'label': 'Cholesterol',
          'desc':
              '> 240 mg/dL indicates high cholesterol, affecting heart health.',
        },
        {
          'label': 'Fasting Blood Sugar',
          'desc': '> 120 mg/dL suggests diabetes risk impacting the heart.',
        },
        {
          'label': 'Rest ECG',
          'desc': 'Abnormal values may indicate underlying heart conditions.',
        },
        {
          'label': 'Max Heart Rate',
          'desc': 'Low max heart rate during stress may be a concern.',
        },
        {
          'label': 'Exercise Angina',
          'desc': 'Presence increases risk of coronary artery disease.',
        },
        {
          'label': 'Oldpeak',
          'desc':
              '> 2 mm depression suggests myocardial ischemia during exercise.',
        },
        {
          'label': 'ST Slope',
          'desc': 'Abnormal slope may reflect risk of heart issues.',
        },
        {
          'label': 'Major Vessels',
          'desc': 'More vessels blocked = higher risk.',
        },
        {
          'label': 'Thalassemia',
          'desc':
              'Types 6 or 7 indicate blood flow abnormalities in the heart.',
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
      body: ListView.builder(
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
              subtitle: Text(
                item['desc']!,
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
            ),
          );
        },
      ),
    );
  }
}
