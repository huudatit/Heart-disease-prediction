import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          "Kết quả đánh giá",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
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
                      Icons.warning_rounded,
                      color: Colors.red[700],
                      size: 40,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Nguy cơ mắc bệnh tim cao",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Phần giải pháp
                Text(
                  "💡 Các giải pháp khuyến nghị:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 15),

                // Danh sách giải pháp với icons
                ...[
                      "Tập thể dục nhẹ mỗi ngày",
                      "Hạn chế muối và chất béo",
                      "Khám định kỳ 3 tháng/lần",
                      "Duy trì tâm lý tích cực",
                    ]
                    .map(
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
                    )
                    ,

                const SizedBox(height: 25),

                // Nút hành động
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Xử lý khi nhấn nút
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
                      'Tìm hiểu thêm',
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
      ),
    );
  }
}
