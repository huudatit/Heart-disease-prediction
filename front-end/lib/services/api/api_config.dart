class ApiConfig {
  // Ví dụ: địa chỉ máy chủ Flask chạy trên mạng nội bộ
  static const String baseUrl = 'http://192.168.1.109:5000';

  // Nếu bạn cần nhiều endpoint khác, có thể gom thêm ở đây:
  static String predictEndpoint() => '$baseUrl/predict';
  static String anotherEndpoint() => '$baseUrl/another';
}
