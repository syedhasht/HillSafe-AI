"""
ML Engine API Views for HillSafe AI

Provides REST API endpoints for machine learning predictions.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .predictor import HillSafePredictor


class PredictRiskView(APIView):
    """
    POST endpoint for landslide risk prediction using ML models.
    
    Endpoint: POST /api/predict/risk/
    
    Request Body:
    {
        "rainfall": 45.5,
        "slope": 35.0,
        "soil": 2.0,
        "lithology": 3
    }
    
    Response:
    {
        "risk_score": 0.85,
        "risk_level": "HIGH",
        "is_safe": false,
        "model_status": "ready"
    }
    """
    
    def post(self, request):
        # Extract parameters from request
        rainfall = request.data.get('rainfall')
        slope = request.data.get('slope')
        soil = request.data.get('soil')
        lithology = request.data.get('lithology')
        
        # Validate required fields
        if any(param is None for param in [rainfall, slope, soil, lithology]):
            return Response(
                {
                    'error': 'Missing required fields',
                    'required': ['rainfall', 'slope', 'soil', 'lithology']
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate data types
        try:
            rainfall = float(rainfall)
            slope = float(slope)
            soil = float(soil)
            lithology = int(lithology)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid data types. rainfall, slope, soil must be numbers; lithology must be an integer'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get predictor instance (singleton)
        predictor = HillSafePredictor()
        
        # Check if model is loaded
        if not predictor.is_model_ready():
            return Response(
                {
                    'error': 'ML model not loaded',
                    'message': 'The prediction model is currently unavailable. Please check server logs.',
                    'model_status': 'not_ready'
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Perform prediction
        risk_score = predictor.predict_risk(rainfall, slope, soil, lithology)
        
        # Determine risk level
        if risk_score > 0.7:
            risk_level = 'HIGH'
            is_safe = False
        elif risk_score > 0.3:
            risk_level = 'MODERATE'
            is_safe = False
        else:
            risk_level = 'LOW'
            is_safe = True
        
        # Return prediction result
        return Response(
            {
                'risk_score': round(risk_score, 3),
                'risk_level': risk_level,
                'is_safe': is_safe,
                'model_status': 'ready',
                'input_params': {
                    'rainfall': rainfall,
                    'slope': slope,
                    'soil': soil,
                    'lithology': lithology
                }
            },
            status=status.HTTP_200_OK
        )


class ModelStatusView(APIView):
    """
    GET endpoint to check ML model loading status.
    
    Endpoint: GET /api/predict/status/
    
    Response:
    {
        "rf_model_loaded": true,
        "lstm_model_loaded": true,
        "scaler_loaded": true,
        "status": "ready"
    }
    """
    
    def get(self, request):
        predictor = HillSafePredictor()
        
        return Response(
            {
                'rf_model_loaded': predictor.rf_model is not None,
                'lstm_model_loaded': predictor.lstm_model is not None,
                'scaler_loaded': predictor.scaler is not None,
                'status': 'ready' if predictor.is_model_ready() else 'not_ready'
            },
            status=status.HTTP_200_OK
        )
