🫀 Heart Disease Prediction System (Flutter + Flask AI)

This project is a full-stack AI system that predicts the risk of heart disease based on user input. It includes:

- 📱 Frontend: A Flutter mobile app for user input and displaying predictions
- ⚙️ Backend: A Flask API server hosting a trained Machine Learning model (e.g. LightGBM or XGBoost)

Project Structure:
------------------

heart-disease-ai-system/
├── front_end/       # Flutter mobile app (client)
├── back_end/        # Flask server with trained ML model
└── README.txt

Features:
---------

- User-friendly interface to input medical data
- ML model trained on heart disease dataset
- Real-time prediction via HTTP API
- Easily extensible to support more features

How to Run the Backend (Flask):
-------------------------------

1. Install Python dependencies

   cd back_end
   pip install -r requirements.txt

2. Run Flask API

   python app.py

   You will see output like:

   Running on http://127.0.0.1:5000

   Make sure the file lgbm_model.pkl (or other model) is in the same folder.

3. Test the API

   Send a POST request to:

   http://127.0.0.1:5000/predict

   With a JSON body like:

   {
     "age": 52,
     "cholesterol": 210,
     "resting_blood_pressure": 130,
     "max_heart_rate": 160,
     "st_depression": 1.0,
     "num_major_vessels": 0,
     "sex": 1,
     "fasting_blood_sugar": 0,
     "exercise_induced_angina": 0,
     "chest_pain_type": 2,
     "resting_ecg": 1,
     "st_slope": 1,
     "thalassemia": 2
   }

How to Run the Frontend (Flutter):
----------------------------------

1. Install dependencies

   cd front_end
   flutter pub get

2. Run the app

   flutter run

   If you are using Android Emulator, connect to the backend using http://10.0.2.2:5000/predict
   If using real device (on same Wi-Fi), replace with your PC IP: http://192.168.x.x:5000/predict

API Connection from Flutter:
----------------------------

Use the http package in Flutter to send data:

  final url = Uri.parse("http://<your-ip>:5000/predict");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(inputData),
  );

ML Model:
---------

The backend uses a trained LightGBM or XGBoost model stored as lgbm_model.pkl. You can retrain or replace this model as needed.

License:
--------

This project is for educational and demonstration purposes. Feel free to use and extend it.
