from flask import Flask, request, jsonify
import joblib
import pandas as pd
import os
import sys

# In ra đường dẫn hiện tại để kiểm tra
print("Current working directory:", os.getcwd())
print("Script directory:", os.path.dirname(os.path.abspath(__file__)))

# Thử nhiều đường dẫn khác nhau
possible_paths = [
    os.path.join(os.path.dirname(__file__), 'lgbm_model.pkl'),
    os.path.join(os.path.dirname(__file__), 'ml_model', 'lgbm_model.pkl'),
    os.path.join(os.getcwd(), 'lgbm_model.pkl'),
    os.path.join(os.getcwd(), 'ml_model', 'lgbm_model.pkl'),
    os.path.join(os.path.dirname(sys.executable), 'lgbm_model.pkl')
]

# Thử load model từ các đường dẫn khác nhau
model = None
for path in possible_paths:
    try:
        print(f"Trying to load model from: {path}")
        model = joblib.load(path)
        print(f"Model successfully loaded from {path}")
        break
    except FileNotFoundError:
        print(f"Model not found at {path}")
    except Exception as e:
        print(f"Error loading model from {path}: {e}")

if model is None:
    print("Could not load the model from any of the specified paths")

# Tạo Flask app
app = Flask(__name__)

# Endpoint API dự đoán
@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model not loaded. Check file path and permissions.'}), 500
    
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