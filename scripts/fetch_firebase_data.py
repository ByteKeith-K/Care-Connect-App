import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

# Initialize Firebase Admin SDK
cred = credentials.Certificate('../scripts/care-connect-app-37a32-firebase-adminsdk-fbsvc-359903fd5d.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Fetch data from Firebase collections
def fetch_data():
    patients_ref = db.collection('patients')
    doctors_notes_ref = db.collection('doctors_notes')

    patients = []
    for doc in patients_ref.stream():
        patient = doc.to_dict()
        patients.append(patient)

    doctors_notes = []
    for doc in doctors_notes_ref.stream():
        note = doc.to_dict()
        doctors_notes.append(note)

    # Convert to DataFrame
    patients_df = pd.DataFrame(patients)
    doctors_notes_df = pd.DataFrame(doctors_notes)

    # Save to CSV for further processing
    patients_df.to_csv('../patients_data.csv', index=False)
    doctors_notes_df.to_csv('../doctors_notes_data.csv', index=False)

    print("Data fetched and saved to CSV files.")

if __name__ == "__main__":
    fetch_data()
