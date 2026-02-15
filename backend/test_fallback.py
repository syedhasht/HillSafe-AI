"""
Test fallback mode and last_updated tracking.
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from django.test import Client
import json

client = Client()

print("=" * 60)
print("Testing API Fallback Mode & Last Updated Tracking")
print("=" * 60)

# Test 1: Trigger data ingestion (will use mock data due to invalid API key)
print("\n[TEST 1] POST /api/ingest/trigger/ (with mock data fallback)")
print("-" * 60)

response = client.post('/api/ingest/trigger/')

if response.status_code == 200:
    data = response.json()
    print(f"Status: {data['status']}")
    print(f"Message: {data['message']}")
    print(f"Regions Updated: {data['updated']}")
    print(f"Alerts Created: {data['alerts_created']}")
    
    print("\nRegion Details:")
    for result in data['results']:
        if 'error' not in result:
            print(f"\n  {result['region_name']}:")
            print(f"    Rainfall: {result['rainfall_mm']}mm")
            print(f"    Temperature: {result['temperature']}C")
            print(f"    Risk Score: {result['risk_score']}")
else:
    print(f"FAIL: {response.status_code}")

# Test 2: Fetch regions to check last_updated field
print("\n\n[TEST 2] GET /api/regions/ (checking last_updated)")
print("-" * 60)

response = client.get('/api/regions/')

if response.status_code == 200:
    regions = response.json()
    print(f"Total Regions: {len(regions)}")
    
    for region in regions:
        print(f"\n{region['name']}:")
        print(f"  Risk Score: {region['current_risk_score']}")
        print(f"  Last Updated: {region['last_updated']}")
else:
    print(f"FAIL: {response.status_code}")

print("\n" + "=" * 60)
print("Tests Completed!")
print("=" * 60)
