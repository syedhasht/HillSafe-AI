"""
Firebase Admin SDK Configuration for HillSafe Backend.

Initializes Firebase Admin SDK for sending push notifications
to mobile devices when high-risk alerts are detected.
"""

import os

import firebase_admin
from django.conf import settings
from firebase_admin import credentials

# Robust path resolution to support monorepos and Render secret files
def _get_service_account_path():
    path1 = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
    if os.path.exists(path1):
        return path1
    path2 = os.path.join(os.path.dirname(settings.BASE_DIR), 'serviceAccountKey.json')
    if os.path.exists(path2):
        return path2
    return path1

SERVICE_ACCOUNT_KEY_PATH = _get_service_account_path()

if not firebase_admin._apps:
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print(f"Firebase Admin SDK initialized successfully using key at: {SERVICE_ACCOUNT_KEY_PATH}")
    except FileNotFoundError:
        print("WARNING: serviceAccountKey.json not found!")
        print(f"   Expected location: {SERVICE_ACCOUNT_KEY_PATH}")
        print("   Firebase push notifications will NOT work until you add this file.")
        print("   Download it from Firebase Console > Project Settings > Service Accounts")
    except Exception as exc:
        print(f"Firebase initialization error: {exc}")
else:
    print("Firebase Admin SDK already initialized")
