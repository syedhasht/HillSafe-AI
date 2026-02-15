"""
ML Engine API Test Script

Tests the /api/predict/risk/ endpoint with high-risk and low-risk scenarios.
Validates response structure, status codes, and risk level classification.

Usage:
    python test_ml_api.py
"""

import requests
import json


def test_ml_prediction_api():
    """
    Test the ML Engine API with different risk scenarios.
    """
    
    # API endpoint
    endpoint_url = "http://127.0.0.1:8000/api/predict/risk/"
    
    # Test scenarios
    test_cases = [
        {
            "name": "High Risk Scenario",
            "payload": {
                'rainfall': 85.0,
                'slope': 40.0,
                'soil': 90.0,
                'lithology': 1
            },
            "expected_level": "HIGH"
        },
        {
            "name": "Low Risk Scenario",
            "payload": {
                'rainfall': 5.0,
                'slope': 10.0,
                'soil': 20.0,
                'lithology': 1
            },
            "expected_level": "LOW"
        }
    ]
    
    print("=" * 80)
    print("ML ENGINE API TEST")
    print("=" * 80)
    print(f"Endpoint: {endpoint_url}\n")
    
    # Run tests for each scenario
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{'-' * 80}")
        print(f"TEST {i}: {test_case['name']}")
        print(f"{'-' * 80}")
        
        payload = test_case['payload']
        expected_level = test_case['expected_level']
        
        print(f"\nRequest Payload:")
        print(json.dumps(payload, indent=2))
        
        try:
            # Send POST request
            response = requests.post(
                endpoint_url,
                json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=10
            )
            
            # Print status code
            print(f"\nResponse Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("Status: SUCCESS")
            else:
                print(f"Status: FAILED (Expected 200, got {response.status_code})")
            
            # Parse and print JSON response
            print(f"\nResponse JSON:")
            response_data = response.json()
            print(json.dumps(response_data, indent=2))
            
            # Validate response structure
            print(f"\nValidation:")
            
            required_fields = ['risk_score', 'risk_level', 'is_safe', 'model_status']
            missing_fields = [field for field in required_fields if field not in response_data]
            
            if missing_fields:
                print(f"[FAIL] Missing fields: {missing_fields}")
            else:
                print(f"[PASS] All required fields present")
            
            # Check risk score range
            if 'risk_score' in response_data:
                risk_score = response_data['risk_score']
                if 0.0 <= risk_score <= 1.0:
                    print(f"[PASS] Risk score within valid range: {risk_score}")
                else:
                    print(f"[FAIL] Risk score out of range: {risk_score}")
            
            # Check risk level
            if 'risk_level' in response_data:
                risk_level = response_data['risk_level']
                if risk_level == expected_level:
                    print(f"[PASS] Risk level matches expected: {risk_level}")
                else:
                    print(f"[WARN] Risk level: {risk_level} (Expected: {expected_level})")
            
            # Check model status
            if 'model_status' in response_data:
                if response_data['model_status'] == 'ready':
                    print(f"[PASS] Model status: ready")
                else:
                    print(f"[WARN] Model status: {response_data['model_status']}")
            
        except requests.exceptions.ConnectionError:
            print("[ERROR] Could not connect to server")
            print("        Make sure Django server is running: python manage.py runserver")
        except requests.exceptions.Timeout:
            print("[ERROR] Request timeout")
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] {e}")
        except json.JSONDecodeError:
            print("[ERROR] Invalid JSON response")
            print(f"Raw response: {response.text}")
    
    print(f"\n{'=' * 80}")
    print("TEST COMPLETE")
    print(f"{'=' * 80}\n")


def test_model_status_endpoint():
    """
    Test the model status endpoint.
    """
    
    endpoint_url = "http://127.0.0.1:8000/api/predict/status/"
    
    print("\n" + "=" * 80)
    print("BONUS TEST: Model Status Endpoint")
    print("=" * 80)
    print(f"Endpoint: {endpoint_url}\n")
    
    try:
        response = requests.get(endpoint_url, timeout=10)
        
        print(f"Response Status Code: {response.status_code}")
        
        if response.status_code == 200:
            print("Status: SUCCESS")
            print(f"\nResponse JSON:")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"Status: FAILED")
            
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] {e}")
    
    print(f"\n{'=' * 80}\n")


if __name__ == "__main__":
    # Test prediction endpoint
    test_ml_prediction_api()
    
    # Test status endpoint
    test_model_status_endpoint()
