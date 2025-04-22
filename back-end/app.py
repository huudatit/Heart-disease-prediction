from flask import Flask, request, jsonify
import joblib
import pandas as pd

# Load mô hình
model = joblib.load('lgbm_model.pkl')

# Tạo Flask app
app = Flask(__name__)

# Endpoint API dự đoán
@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Nhận dữ liệu JSON từ Flutter
        input_data = request.get_json()

        # Convert thành DataFrame
        input_df = pd.DataFrame([input_data])

        # Dự đoán
        prediction = model.predict(input_df)[0]
        probability = model.predict_proba(input_df)[0][1]

        # Trả kết quả
        return jsonify({
            'prediction': int(prediction),
            'probability': float(probability)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

# Chạy server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
