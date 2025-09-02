import pandas as pd
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from imblearn.over_sampling import SMOTE
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import classification_report
import joblib
import random
from sklearn.model_selection import GridSearchCV

# --- Synthetic Data Generation ---
def generate_synthetic_patient_data(num_patients=2000, seed=42):
    random.seed(seed)
    np.random.seed(seed)
    genders = ['Male', 'Female', 'Other']
    # Expanded list of global diseases
    medical_histories = [
        'Diabetes', 'Hypertension', 'Heart Disease', 'Asthma', 'None', 'Cancer', 'Tuberculosis', 'HIV/AIDS',
        'Chronic Kidney Disease', 'COPD', 'Obesity', 'Malaria', 'Dengue', 'Hepatitis', 'Epilepsy', 'Depression',
        'Arthritis', 'Alzheimer', 'Parkinson', 'Sickle Cell', 'Thalassemia', 'Cystic Fibrosis', 'Lupus', 'Multiple Sclerosis'
    ]
    diagnoses = [
        'AIDS', 'Asthma', 'Flu', 'Pneumonia', 'Stroke', 'Bronchitis', 'COVID-19', 'Ulcer', 'Migraine', 'Gastritis',
        'Cancer', 'Tuberculosis', 'Malaria', 'Dengue', 'Hepatitis', 'Epilepsy', 'Depression', 'Arthritis', 'Alzheimer',
        'Parkinson', 'Sickle Cell', 'Thalassemia', 'Cystic Fibrosis', 'Lupus', 'Multiple Sclerosis', 'Ebola', 'Zika', 'Cholera', 'Measles', 'Polio'
    ]
    outcomes = ['deteriorating', 'stable', 'recovered']
    rows = []
    for i in range(num_patients):
        patient_id = f'PAT{str(i+1).zfill(4)}'
        age = np.random.randint(0, 100)
        gender = random.choice(genders)
        has_medical_aid = np.random.randint(0, 2)
        heart_rate = np.random.randint(50, 150)
        systolic_bp = np.random.randint(80, 200)
        diastolic_bp = np.random.randint(50, 130)
        temperature = np.round(np.random.uniform(34.0, 41.5), 1)
        respiratory_rate = np.random.randint(8, 40)
        oxygen_saturation = np.random.randint(70, 100)
        height = np.random.randint(120, 210)
        weight = np.random.randint(30, 180)
        medical_history = random.choice(medical_histories)
        diagnosis = random.choice(diagnoses)
        outcome = random.choices(outcomes, weights=[0.2, 0.5, 0.3])[0]
        rows.append([
            patient_id, age, gender, has_medical_aid, heart_rate, systolic_bp, diastolic_bp,
            temperature, respiratory_rate, oxygen_saturation, height, weight,
            medical_history, diagnosis, outcome
        ])
    columns = [
        'patientId','age','gender','hasMedicalAid','heartRate','systolicBP','diastolicBP',
        'temperature','respiratoryRate','oxygenSaturation','height','weight',
        'medicalHistory','diagnosis','outcome'
    ]
    df = pd.DataFrame(rows, columns=columns)
    df.to_csv('scripts/sample_patient_data.csv', index=False)

# Generate and save synthetic data
if __name__ == "__main__":
    generate_synthetic_patient_data(num_patients=1000)

    # Load sample data
    sample_data = pd.read_csv('scripts/sample_patient_data.csv')

    # Preprocess the data
    features = [
        'age', 'hasMedicalAid', 'heartRate', 'systolicBP', 'diastolicBP',
        'temperature', 'respiratoryRate', 'oxygenSaturation', 'height', 'weight'
    ]
    X = sample_data[features]
    y = sample_data['outcome']

    # Encode categorical target variable
    y = y.astype('category').cat.codes

    # Ensure proper feature scaling
    scaler = MinMaxScaler()
    X_scaled = scaler.fit_transform(X)
    joblib.dump(scaler, 'scripts/minmax_scaler.joblib')

    # Handle imbalanced classes using SMOTE
    smote = SMOTE(random_state=42)
    X_resampled, y_resampled = smote.fit_resample(X_scaled, y)

    # Split the resampled data
    X_train, X_test, y_train, y_test = train_test_split(X_resampled, y_resampled, test_size=0.2, random_state=42)

    # Use a larger hyperparameter grid for higher accuracy
    rf_params = {
        'n_estimators': [100, 200, 300, 400],
        'max_depth': [None, 10, 20, 30, 40],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4]
    }
    rf_grid = GridSearchCV(RandomForestClassifier(random_state=42), rf_params, cv=5, n_jobs=-1, scoring='accuracy')
    rf_grid.fit(X_train, y_train)
    rf_model = rf_grid.best_estimator_
    print('Best Random Forest Params:', rf_grid.best_params_)
    joblib.dump(rf_model, 'scripts/random_forest_patient_outcome.joblib')

    knn_params = {'n_neighbors': [3, 5, 7, 9, 11], 'weights': ['uniform', 'distance']}
    knn_grid = GridSearchCV(KNeighborsClassifier(), knn_params, cv=5, n_jobs=-1, scoring='accuracy')
    knn_grid.fit(X_train, y_train)
    knn_model = knn_grid.best_estimator_
    print('Best KNN Params:', knn_grid.best_params_)
    joblib.dump(knn_model, 'scripts/knn_patient_treatment.joblib')

    # Evaluate models
    rf_predictions = rf_model.predict(X_test)
    knn_predictions = knn_model.predict(X_test)

    print("Random Forest Classification Report:\n", classification_report(y_test, rf_predictions))
    print("KNN Classification Report:\n", classification_report(y_test, knn_predictions))