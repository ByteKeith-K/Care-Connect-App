import logging
from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
from datetime import datetime
import os
import statsmodels.api as sm
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)

# Setup logging
logging.basicConfig(filename='ml_predictions.log', level=logging.INFO, format='%(asctime)s %(message)s')

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))

# Load trained models
rf_model = joblib.load(os.path.join(SCRIPTS_DIR, 'random_forest_patient_outcome.joblib'))
knn_model = joblib.load(os.path.join(SCRIPTS_DIR, 'knn_patient_treatment.joblib'))
scaler = joblib.load(os.path.join(SCRIPTS_DIR, 'minmax_scaler.joblib'))

# Load category mappings from sample data
sample_data = pd.read_csv(os.path.join(SCRIPTS_DIR, 'sample_patient_data.csv'))
outcome_categories = sample_data['outcome'].astype('category').cat.categories.tolist()
treatment_categories = sample_data['diagnosis'].astype('category').cat.categories.tolist()
gender_categories = sample_data['gender'].astype('category').cat.categories.tolist()
medical_history_categories = sample_data['medicalHistory'].astype('category').cat.categories.tolist()

# Define the order of features expected by the models
FEATURE_ORDER = [
    'age', 'hasMedicalAid', 'heartRate', 'systolicBP', 'diastolicBP',
    'temperature', 'respiratoryRate', 'oxygenSaturation', 'height', 'weight'
]

@app.route('/predict_outcome', methods=['POST'])
def predict_outcome():
    data = request.json
    features = [data.get(f, 0) for f in FEATURE_ORDER]
    features_scaled = scaler.transform([features])
    prediction_code = rf_model.predict(features_scaled)[0]
    prediction_label = outcome_categories[prediction_code] if prediction_code < len(outcome_categories) else str(prediction_code)
    # Probability/confidence
    if hasattr(rf_model, 'predict_proba'):
        proba = float(np.max(rf_model.predict_proba(features_scaled)))
    else:
        proba = None
    # Logging
    logging.info(f"Outcome prediction | Input: {data} | Prediction: {prediction_label} | Probability: {proba}")
    return jsonify({'prediction': prediction_label, 'probability': proba})

@app.route('/predict_treatment', methods=['POST'])
def predict_treatment():
    data = request.json
    features = [data.get(f, 0) for f in FEATURE_ORDER]
    features_scaled = scaler.transform([features])
    prediction_code = knn_model.predict(features_scaled)[0]
    prediction_label = treatment_categories[prediction_code] if prediction_code < len(treatment_categories) else str(prediction_code)
    # Probability/confidence
    if hasattr(knn_model, 'predict_proba'):
        proba = float(np.max(knn_model.predict_proba(features_scaled)))
    else:
        proba = None
    # Logging
    logging.info(f"Treatment prediction | Input: {data} | Prediction: {prediction_label} | Probability: {proba}")
    return jsonify({'prediction': prediction_label, 'probability': proba})

@app.route('/categorical_options', methods=['GET'])
def categorical_options():
    return jsonify({
        'gender': gender_categories,
        'medicalHistory': medical_history_categories,
        'diagnosis': treatment_categories,
        'outcome': outcome_categories
    })

@app.route('/statistics', methods=['GET'])
def statistics():
    # Initialize Firestore if not already done
    if not firebase_admin._apps:
        cred = credentials.Certificate(os.path.join(SCRIPTS_DIR, 'care-connect-app-37a32-firebase-adminsdk-fbsvc-359903fd5d.json'))
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    # Get patient_id from query params (if any)
    patient_id = request.args.get('patient_id')

    # Fetch all patients
    patients = []
    for doc in db.collection('patients').stream():
        d = doc.to_dict()
        d['id'] = doc.id
        patients.append(d)
    patients_df = pd.DataFrame(patients)

    # Fetch all vital signs
    vitals = []
    for doc in db.collection('vitalSigns').stream():
        d = doc.to_dict()
        d['id'] = doc.id
        vitals.append(d)
    vitals_df = pd.DataFrame(vitals)

    # If patient_id is provided, filter both dataframes
    if patient_id:
        patients_df = patients_df[patients_df['id'] == patient_id]
        vitals_df = vitals_df[vitals_df['patientId'] == patient_id]

    # Convert string fields to numeric
    for col in ['age', 'heartRate', 'systolicBP', 'diastolicBP', 'temperature', 'respiratoryRate', 'oxygenSaturation', 'height', 'weight']:
        if col in patients_df.columns:
            patients_df[col] = pd.to_numeric(patients_df[col], errors='coerce')
        if col in vitals_df.columns:
            vitals_df[col] = pd.to_numeric(vitals_df[col], errors='coerce')

    # Merge on patientId and compute regression of systolicBP vs. age
    merged = pd.merge(vitals_df, patients_df, left_on='patientId', right_on='id', suffixes=('_vital', '_patient'))
    results = {}

    if not merged.empty and 'systolicBP' in merged and 'age' in merged:
        X = merged[['age']].dropna()
        y = merged.loc[X.index, 'systolicBP']
        X = sm.add_constant(X)
        model = sm.OLS(y, X).fit()
        results['systolicBP_vs_age'] = {
            'params': model.params.replace({np.nan: None}).to_dict(),
            'pvalues': model.pvalues.replace({np.nan: None}).to_dict(),
            'rsquared': None if pd.isna(model.rsquared) else model.rsquared,
            'summary': model.summary().as_text()
        }

    # Example: Summary statistics
    summary = merged.describe(include='all').replace({np.nan: None, np.inf: None, -np.inf: None})
    results['summary'] = summary.to_dict()

    # Correlation matrix for numeric columns
    corr = merged.corr(numeric_only=True).replace({np.nan: None, np.inf: None, -np.inf: None})
    results['correlation_matrix'] = corr.to_dict()

    # Summary statistics by gender (if gender exists)
    if 'gender' in merged.columns:
        by_gender = merged.groupby('gender').describe().replace({np.nan: None, np.inf: None, -np.inf: None})
        # Convert multi-index columns to string keys for JSON
        by_gender = by_gender.swaplevel(axis=1)
        by_gender.columns = ['_'.join(map(str, col)).strip() for col in by_gender.columns.values]
        results['summary_by_gender'] = by_gender.to_dict(orient='index')

    # Group summary by age ranges
    if 'age' in merged.columns:
        bins = [0, 18, 30, 45, 60, 75, 120]
        labels = ['0-17', '18-29', '30-44', '45-59', '60-74', '75+']
        merged['age_group'] = pd.cut(merged['age'], bins=bins, labels=labels, right=False)
        by_age_group = merged.groupby('age_group').describe().replace({np.nan: None, np.inf: None, -np.inf: None})
        by_age_group = by_age_group.swaplevel(axis=1)
        by_age_group.columns = ['_'.join(map(str, col)).strip() for col in by_age_group.columns.values]
        results['summary_by_age_group'] = by_age_group.to_dict(orient='index')

    # Group summary by medical history
    if 'medicalHistory' in merged.columns:
        by_medhist = merged.groupby('medicalHistory').describe().replace({np.nan: None, np.inf: None, -np.inf: None})
        by_medhist = by_medhist.swaplevel(axis=1)
        by_medhist.columns = ['_'.join(map(str, col)).strip() for col in by_medhist.columns.values]
        results['summary_by_medical_history'] = by_medhist.to_dict(orient='index')

    # Chart data: time series of average systolicBP by date (if timestamp exists)
    if 'timestamp' in merged.columns:
        merged['date'] = pd.to_datetime(merged['timestamp'], errors='coerce').dt.date
        bp_time_series = merged.groupby('date')['systolicBP'].mean().dropna().reset_index()
        results['bp_time_series'] = bp_time_series.to_dict(orient='records')

    # Chart data: histogram of age
    if 'age' in merged.columns:
        age_hist, age_bins = np.histogram(merged['age'].dropna(), bins=[0, 18, 30, 45, 60, 75, 120])
        results['age_histogram'] = {
            'bins': [0, 18, 30, 45, 60, 75, 120],
            'counts': age_hist.tolist()
        }

    return jsonify(results)

@app.route('/patients', methods=['GET'])
def get_patients():
    if not firebase_admin._apps:
        cred = credentials.Certificate(os.path.join(SCRIPTS_DIR, 'care-connect-app-37a32-firebase-adminsdk-fbsvc-359903fd5d.json'))
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    patients = []
    for doc in db.collection('patients').stream():
        d = doc.to_dict()
        d['id'] = doc.id
        patients.append({'id': d['id'], 'name': d.get('name', '')})
    return jsonify(patients)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
