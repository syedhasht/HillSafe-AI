"""
Test script for HillSafe AI REST API endpoints.
This script verifies that all API endpoints are working correctly.
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from regions.models import Region
from alerts.models import Alert
import json

User = get_user_model()
client = Client()

print("=" * 60)
print("HillSafe AI - REST API Endpoint Tests")
print("=" * 60)

# Test 1: Login Endpoint
print("\n[TEST 1] Testing Login Endpoint (POST /api/login/)")
print("-" * 60)

login_data = {
    'username': 'admin',
    'password': 'admin123'
}

response = client.post(
    '/api/login/',
    data=json.dumps(login_data),
    content_type='application/json'
)

print(f"Status Code: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    print("SUCCESS: Login endpoint working correctly!")
    token = data.get('token')
else:
    print(f"FAIL: Login failed: {response.content}")
    token = None

# Test 2: Regions Endpoint
print("\n[TEST 2] Testing Regions Endpoint (GET /api/regions/)")
print("-" * 60)

response = client.get('/api/regions/')
print(f"Status Code: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    print(f"Number of regions: {len(data)}")
    if data:
        print(f"Sample region: {json.dumps(data[0], indent=2)}")
    else:
        print("No regions found (this is normal if database is empty)")
    print("SUCCESS: Regions endpoint working correctly!")
else:
    print(f"FAIL: Regions endpoint failed: {response.content}")

# Test 3: Alerts Endpoint
print("\n[TEST 3] Testing Alerts Endpoint (GET /api/alerts/)")
print("-" * 60)

response = client.get('/api/alerts/')
print(f"Status Code: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    print(f"Number of active alerts: {len(data)}")
    if data:
        print(f"Sample alert: {json.dumps(data[0], indent=2)}")
    else:
        print("No active alerts found (this is normal if database is empty)")
    print("SUCCESS: Alerts endpoint working correctly!")
else:
    print(f"FAIL: Alerts endpoint failed: {response.content}")

# Test 4: Create sample data for demonstration
print("\n[TEST 4] Creating Sample Data")
print("-" * 60)

# Create a sample region
region, created = Region.objects.get_or_create(
    name="Murree Hills",
    district="Rawalpindi",
    defaults={
        'latitude': 33.9070,
        'longitude': 73.3903,
        'current_risk_score': 0.75
    }
)

if created:
    print(f"SUCCESS: Created sample region: {region.name}")
else:
    print(f"SUCCESS: Sample region already exists: {region.name}")

# Create a sample alert
alert, created = Alert.objects.get_or_create(
    region=region,
    severity='HIGH',
    defaults={
        'message': 'Heavy rainfall detected. Risk of landslides in hilly areas.',
        'is_active': True
    }
)

if created:
    print(f"SUCCESS: Created sample alert for {region.name}")
else:
    print(f"SUCCESS: Sample alert already exists for {region.name}")

# Re-test endpoints with data
print("\n[TEST 5] Re-testing Endpoints with Sample Data")
print("-" * 60)

response = client.get('/api/regions/')
data = response.json()
print(f"Regions count: {len(data)}")
if data:
    print(f"Sample region data: {json.dumps(data[0], indent=2)}")

response = client.get('/api/alerts/')
data = response.json()
print(f"Active alerts count: {len(data)}")
if data:
    print(f"Sample alert data: {json.dumps(data[0], indent=2)}")

print("\n" + "=" * 60)
print("All API Endpoint Tests Completed!")
print("=" * 60)

print("\nAPI Endpoints Summary:")
print("  - POST /api/login/     - Authentication (returns token)")
print("  - GET  /api/regions/   - List all regions")
print("  - GET  /api/alerts/    - List active alerts")

print("\nAdmin Credentials:")
print("  Username: admin")
print("  Password: admin123")

print("\nTo start the server manually:")
print("  python manage.py runserver")
print("  Then access: http://127.0.0.1:8000/api/")
