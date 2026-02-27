import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase app globally.
# In a real setup, provide the path to your service account key JSON file via an env variable.
# For example: os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/path/to/serviceAccountKey.json"

# To prevent re-initialization if the module is reloaded
if not firebase_admin._apps:
    try:
        # Check if credential file is provided
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            # Fallback for local development if application default credentials are fine
            # or mock initialization if we want to bypass during tests.
            firebase_admin.initialize_app()
    except Exception as e:
        print(f"Warning: Firebase initialization failed: {e}")

# Function to get a Firestore client
def get_db():
    try:
        return firestore.client()
    except Exception as e:
        print(f"Warning: Could not get Firestore client: {e}")
        return None
