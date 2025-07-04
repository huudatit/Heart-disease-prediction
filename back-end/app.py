# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
from pathlib import Path
from datetime import datetime

# 1) Khởi tạo Flask và CORS
app = Flask(__name__)
CORS(app)

# 2) Xác định đường dẫn đến model và scaler
BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / 'ml_model' / 'random_forest_model.pkl'

# 3) Load model & scaler
try:
    model = joblib.load(MODEL_PATH)
    print(f"✅ Loaded model from {MODEL_PATH}")
except Exception as e:
    model = None
    print(f"❌ Failed to load model: {e}")

# 4) Định nghĩa thứ tự feature (phải khớp với lúc train)
FEATURE_ORDER = [
    'age','sex','cp','trestbps','chol',
    'fbs','restecg','thalach','exang',
    'oldpeak','slope','ca','thal'
]

def get_risk_level(p):
    if p >= 0.85:   return 'High'
    if p >= 0.4:   return 'Medium'
    return 'Low'

def get_recommendations(pred, prob, data):
    recs = []
    if pred == 1:
        recs += [
            "Tham khảo bác sĩ tim mạch",
            "Làm thêm ECG, siêu âm tim"
        ]
    if data['age'] > 50:
        recs.append("Theo dõi tim mạch do tuổi cao")
    if data['trestbps'] > 140:
        recs.append("Kiểm soát huyết áp: giảm muối, tập thể dục")
    if data['chol'] > 240:
        recs.append("Kiểm soát cholesterol: ăn ít béo, vận động")
    if not recs:
        recs += ["Duy trì lối sống lành mạnh", "Khám định kỳ"]
    return recs

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model chưa load được'}), 500

    payload = request.get_json(force=True)
    # Check đủ 13 trường
    for f in FEATURE_ORDER:
        if f not in payload:
            return jsonify({'error': f'Missing field: {f}'}), 400

    # Xây DataFrame theo đúng thứ tự
    row = [payload[f] for f in FEATURE_ORDER]
    df = pd.DataFrame([row], columns=FEATURE_ORDER)

    # Scale nếu có scaler
    X = df.values

    # Dự đoán
    pred = int(model.predict(X)[0])
    prob = float(model.predict_proba(X)[0][1])

    result = {
        'prediction': pred,
        'probability': prob,
        'risk_level': get_risk_level(prob),
        'timestamp': datetime.now().isoformat(),
        'recommendations': get_recommendations(pred, prob, payload)
    }
    return jsonify(result), 200

# Các endpoint khác (patient, history…) giữ nguyên nếu cần

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
