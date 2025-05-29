import 'package:flutter/material.dart';
import 'package:dacn_app/input_form_screen.dart';

class ResultScreen extends StatelessWidget {
  final int prediction;
  final double probability;
  final Map<String, dynamic> inputData;

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.probability,
    required this.inputData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          "Kết quả đánh giá",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Kết quả dự đoán
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần kết luận
                    Row(
                      children: [
                        Icon(
                          prediction == 1
                              ? Icons.warning_rounded
                              : Icons.check_circle_outline,
                          color:
                              prediction == 1
                                  ? Colors.red[700]
                                  : Colors.green[700],
                          size: 40,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            prediction == 1
                                ? "Nguy cơ mắc bệnh tim cao"
                                : "Nguy cơ mắc bệnh tim thấp",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  prediction == 1
                                      ? Colors.red[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Xác suất
                    Text(
                      "Xác suất: ${(probability * 100).toStringAsFixed(2)}%",
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Thông tin chi tiết đầu vào
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chi tiết đầu vào",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...inputData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLocalizedLabel(entry.key),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Phần giải pháp
              prediction == 1
                  ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "💡 Các giải pháp khuyến nghị:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          "Tập thể dục nhẹ mỗi ngày",
                          "Hạn chế muối và chất béo",
                          "Khám định kỳ 3 tháng/lần",
                          "Duy trì tâm lý tích cực",
                        ].map(
                          (solution) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    solution,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox(),

              const SizedBox(height: 20),

              // Nút quay lại
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InputFormScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Dự đoán lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm chuyển đổi nhãn
  String _getLocalizedLabel(String key) {
    final labels = {
      'age': 'Tuổi',
      'sex': 'Giới tính',
      'cp': 'Loại đau ngực',
      'trestbps': 'Huyết áp nghỉ (mmHg)',
      'chol': 'Cholesterol (mg/dL)',
      'fbs': 'Đường huyết lúc đói',
      'restecg': 'Điện tâm đồ nghỉ',
      'thalach': 'Nhịp tim tối đa',
      'exang': 'Đau khi vận động',
      'oldpeak': 'Độ suy giảm ST',
      'slope': 'Độ dốc ST',
      'ca': 'Số lượng mạch chính',
      'thal': 'Thalassemia',
    };
    return labels[key] ?? key;
  }

  // Hàm chuyển đổi giá trị
  String _transformValue(String key, dynamic value) {
    switch (key) {
      case 'sex':
        return value == 1 ? 'Nam' : 'Nữ';
      case 'cp':
        final cpLabels = [
          'Không đau',
          'Đau thông thường',
          'Đau không điển hình',
          'Đau nghiêm trọng',
        ];
        return cpLabels[value] ?? value.toString();
      case 'fbs':
        return value == 1 ? 'Cao (> 120 mg/dL)' : 'Bình thường (≤ 120 mg/dL)';
      case 'restecg':
        final restecgLabels = [
          'Bình thường',
          'Bất thường',
          'Dấu hiệu điển hình',
        ];
        return restecgLabels[value] ?? value.toString();
      case 'exang':
        return value == 1 ? 'Có' : 'Không';
      case 'slope':
        final slopeLabels = ['Không bằng phẳng', 'Độ dốc đều', 'Độ dốc xuống'];
        return slopeLabels[value] ?? value.toString();
      case 'thal':
        final thalLabels = [
          '',
          'Bình thường',
          'Khuyết tật cố định',
          'Khuyết tật thuận nghịch',
        ];
        return thalLabels[value] ?? value.toString();
      default:
        return value.toString();
    }
  }
}
