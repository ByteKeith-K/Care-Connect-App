import os
from flask import Flask, request, jsonify
from openai import OpenAI
from flask_cors import CORS
from dotenv import load_dotenv
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
import pytz
import joblib
import numpy as np
from scripts.ml_features import ML_FEATURES

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app, resources={
    r"/analyze_note": {"origins": os.getenv('ALLOWED_ORIGINS', "*")}
})

# Configure logging
handler = RotatingFileHandler('app.log', maxBytes=10000, backupCount=3)
handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
))
app.logger.addHandler(handler)
app.logger.setLevel(logging.INFO)

# Initialize OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# Rate limiting storage (in production, use Redis)
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Load the trained Random Forest model once at startup
rf_model = joblib.load('random_forest_patient_outcome.joblib')
# Load the trained KNN model
knn_model = joblib.load('knn_patient_treatment.joblib')

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now(pytz.utc).isoformat()})

@app.route('/analyze_note', methods=['POST'])
@limiter.limit("10 per minute")  # Adjust based on your needs
def analyze_note():
    """
    Analyze clinical notes and return AI-generated insights
    Sample request body: {"note": "Patient presents with fever and cough..."}
    """
    start_time = datetime.now()
    
    # Validate input
    data = request.get_json()
    if not data:
        app.logger.warning("Empty request received")
        return jsonify({'error': 'Request body must be JSON'}), 400
    
    note = data.get('note', '').strip()
    if not note:
        app.logger.warning("Empty note received")
        return jsonify({'error': 'No note provided'}), 400
    
    if len(note) > 10000:  # ~10k characters max
        app.logger.warning(f"Oversized note received ({len(note)} chars)")
        return jsonify({'error': 'Note too long (max 10,000 characters)'}), 400
    
    try:
        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-3.5-turbo-0125",  # or "gpt-4o" when available
            messages=[
                {
                    "role": "system",
                    "content": """You are a medical assistant. Analyze the clinical note and:
1. Identify key symptoms/conditions
2. Flag urgent concerns (highlight with ⚠️)
3. Suggest potential diagnoses (mark as DDx:)
4. Recommend next steps
Keep response under 300 tokens. Use bullet points."""
                },
                {"role": "user", "content": note}
            ],
            temperature=0.3,  # Lower for medical accuracy
            max_tokens=300,
            top_p=0.9
        )
        
        analysis = response.choices[0].message.content
        tokens_used = response.usage.total_tokens
        
        # Log successful request
        duration = (datetime.now() - start_time).total_seconds()
        app.logger.info(
            f"Note analyzed. Tokens: {tokens_used}, "
            f"Duration: {duration:.2f}s, "
            f"Note length: {len(note)} chars"
        )
        
        return jsonify({
            'analysis': analysis,
            'metadata': {
                'model': response.model,
                'tokens_used': tokens_used,
                'processing_time': f"{duration:.2f}s"
            }
        })
        
    except Exception as e:
        app.logger.error(f"Error analyzing note: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'Analysis failed',
            'details': str(e)
        }), 500

@app.route('/predict_outcome', methods=['POST'])
@limiter.limit("10 per minute")
def predict_outcome():
    """
    Predict patient risk using the trained Random Forest model.
    Expects JSON with the required features.
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400
    try:
        # Feature extraction and preprocessing
        def extract_urgent_flag(note):
            urgent_keywords = ['urgent', 'critical', 'pain', 'severe', 'collapse', 'unstable']
            note = str(note).lower()
            return int(any(kw in note for kw in urgent_keywords))
        def count_symptoms(note):
            symptoms = ['pain', 'fever', 'cough', 'dizzy', 'nausea', 'vomit', 'bleed', 'swelling', 'infection', 'weakness']
            note = str(note).lower()
            return sum(note.count(sym) for sym in symptoms)
        features = {
            'age': data.get('age', 0),
            'gender_encoded': 1 if str(data.get('gender', '')).lower() == 'male' else 0,
            'systolicBP': data.get('systolicBP', 0),
            'diastolicBP': data.get('diastolicBP', 0),
            'heartRate': data.get('heartRate', 0),
            'temperature': data.get('temperature', 0.0),
            'oxygenSaturation': data.get('oxygenSaturation', 0),
            'respiratoryRate': data.get('respiratoryRate', 0),
            'weight': data.get('weight', 0.0),
            'height': data.get('height', 0.0),
            'medical_history_flag': 1 if str(data.get('medicalHistory', '')).strip() else 0,
            'urgent_in_note': extract_urgent_flag(data.get('doctorNote', '')),
            'symptom_count': count_symptoms(data.get('doctorNote', '')),
        }
        X = np.array([[features[f] for f in ML_FEATURES]])
        pred = rf_model.predict(X)[0]
        proba = float(rf_model.predict_proba(X)[0][1])
        return jsonify({
            'prediction': int(pred),
            'risk_label': 'At Risk' if pred == 1 else 'Not At Risk',
            'probability': proba
        })
    except Exception as e:
        app.logger.error(f"Error in ML prediction: {str(e)}", exc_info=True)
        return jsonify({'error': 'Prediction failed', 'details': str(e)}), 500

@app.route('/predict', methods=['POST'])
@limiter.limit("10 per minute")
def predict():
    """
    Predict patient outcomes based on input features.
    Sample request body: {"features": {"diastolicBP": 60, "heartRate": 88, ...}}
    """
    data = request.get_json()
    if not data or 'features' not in data:
        return jsonify({'error': 'Request must include a JSON body with a "features" key'}), 400

    features = data['features']
    try:
        # Ensure the features are in the correct order
        input_features = [features.get(key, 0) for key in ML_FEATURES]
        prediction = rf_model.predict([input_features])[0]
        return jsonify({'prediction': prediction}), 200
    except Exception as e:
        app.logger.error(f"Prediction error: {e}")
        return jsonify({'error': 'Failed to make prediction'}), 500

@app.route('/statistics', methods=['GET'])
@limiter.limit("10 per minute")
def statistics():
    """
    Provide statistical analysis of patient data.
    """
    try:
        # Example statistics (replace with actual calculations)
        stats = {
            'total_patients': 100,
            'average_heart_rate': 75,
            'average_blood_pressure': {
                'systolic': 120,
                'diastolic': 80
            },
            'critical_cases': 5
        }
        return jsonify(stats), 200
    except Exception as e:
        app.logger.error(f"Statistics error: {e}")
        return jsonify({'error': 'Failed to fetch statistics'}), 500

@app.route('/treatment', methods=['POST'])
@limiter.limit("10 per minute")
def treatment():
    """
    Provide personalized treatment plans using KNN.
    Sample request body: {"features": {"age": 30, "heartRate": 84, ...}}
    """
    data = request.get_json()
    if not data or 'features' not in data:
        return jsonify({'error': 'Request must include a JSON body with a "features" key'}), 400

    features = data['features']
    try:
        # Ensure the features are in the correct order
        input_features = [features.get(key, 0) for key in ML_FEATURES]
        treatment_plan = knn_model.predict([input_features])[0]
        return jsonify({'treatment_plan': treatment_plan}), 200
    except Exception as e:
        app.logger.error(f"Treatment error: {e}")
        return jsonify({'error': 'Failed to provide treatment plan'}), 500

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, threaded=True)