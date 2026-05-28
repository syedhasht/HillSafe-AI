"""
Firebase Admin SDK Configuration for HillSafe Backend.

Initializes Firebase Admin SDK for sending push notifications
to mobile devices when high-risk alerts are detected.
"""

import os

import firebase_admin
from django.conf import settings
from firebase_admin import credentials

SERVICE_ACCOUNT_KEY_PATH = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')

if not firebase_admin._apps:
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK initialized successfully")
    except FileNotFoundError:
        print("WARNING: serviceAccountKey.json not found!")
        print(f"   Expected location: {SERVICE_ACCOUNT_KEY_PATH.replace('backend', 'Backend')}")
        print("   Firebase push notifications will NOT work until you add this file.")
        print("   Download it from Firebase Console > Project Settings > Service Accounts")
    except Exception as exc:
        print(f"Firebase initialization error: {exc}")
else:
    print("Firebase Admin SDK already initialized")
