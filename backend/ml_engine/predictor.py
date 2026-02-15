"""
HillSafe AI - Machine Learning Predictor Module

This module implements a singleton pattern to load pre-trained ML models once
and provide risk prediction capabilities for landslide detection.

Models:
- Random Forest: Landslide risk classification
- LSTM: Rainfall pattern prediction
- Scaler: Weather data normalization
"""

import os
import joblib
import numpy as np
from django.conf import settings


class HillSafePredictor:
    """
    Singleton class for loading and using pre-trained ML models.
    Models are loaded once on first instantiation and reused.
    """
    
    _instance = None
    _models_loaded = False
    
    def __new__(cls):
        """
        Singleton pattern: Return existing instance or create new one.
        Models are loaded only once.
        """
        if cls._instance is None:
            cls._instance = super(HillSafePredictor, cls).__new__(cls)
            cls._instance._load_models()
        return cls._instance
    
    def _load_models(self):
        """
        Load all ML models from the models directory.
        Uses try-except to handle missing files gracefully.
        """
        if HillSafePredictor._models_loaded:
            return
        
        # Determine models directory path
        models_dir = os.path.join(settings.BASE_DIR, 'ml_engine', 'models')
        
        print(f"Loading ML models from: {models_dir}")
        
        # Initialize models to None
        self.rf_model = None
        self.lstm_model = None
        self.scaler = None
        
        # Load Random Forest Model (.pkl)
        try:
            rf_path = os.path.join(models_dir, 'landslide_rf_model.pkl')
            self.rf_model = joblib.load(rf_path)
            print(f"✓ Random Forest model loaded successfully")
        except FileNotFoundError:
            print(f"⚠️ WARNING: landslide_rf_model.pkl not found at {rf_path}")
        except Exception as e:
            print(f"⚠️ ERROR loading Random Forest model: {e}")
        
        # Load LSTM Model (.h5)
        try:
            import tensorflow as tf
            lstm_path = os.path.join(models_dir, 'rainfall_lstm.h5')
            self.lstm_model = tf.keras.models.load_model(lstm_path)
            print(f"✓ LSTM model loaded successfully")
        except FileNotFoundError:
            print(f"⚠️ WARNING: rainfall_lstm.h5 not found at {lstm_path}")
        except Exception as e:
            print(f"⚠️ ERROR loading LSTM model: {e}")
        
        # Load Weather Scaler (.pkl)
        try:
            scaler_path = os.path.join(models_dir, 'weather_scaler.pkl')
            self.scaler = joblib.load(scaler_path)
            print(f"✓ Weather scaler loaded successfully")
        except FileNotFoundError:
            print(f"⚠️ WARNING: weather_scaler.pkl not found at {scaler_path}")
        except Exception as e:
            print(f"⚠️ ERROR loading scaler: {e}")
        
        HillSafePredictor._models_loaded = True
        print("ML Engine initialization complete")
    
    def predict_risk(self, rainfall, slope, soil, lithology):
        """
        Predict landslide risk using the Random Forest model.
        
        Args:
            rainfall (float): Rainfall amount in mm
            slope (float): Slope angle in degrees
            soil (float): Soil type index
            lithology (int): Lithology type index
        
        Returns:
            float: Risk probability (0.0 to 1.0)
        """
        if self.rf_model is None:
            print("⚠️ Random Forest model not loaded. Returning default risk.")
            return 0.0
        
        try:
            # Prepare input features as numpy array
            # Shape: (1, 4) for single prediction
            features = np.array([[rainfall, slope, soil, lithology]])
            
            # Get probability predictions
            # predict_proba returns [[prob_safe, prob_danger]]
            probabilities = self.rf_model.predict_proba(features)
            
            # Return probability of danger (second column)
            risk_score = float(probabilities[0][1])
            
            print(f"Prediction: rainfall={rainfall}, slope={slope}, soil={soil}, lithology={lithology} → risk={risk_score:.3f}")
            
            return risk_score
            
        except Exception as e:
            print(f"⚠️ ERROR during prediction: {e}")
            return 0.0
    
    def predict_rainfall_trend(self, historical_data):
        """
        Predict future rainfall using the LSTM model.
        
        Args:
            historical_data (list): List of recent rainfall values
        
        Returns:
            float: Predicted rainfall value
        """
        if self.lstm_model is None:
            print("⚠️ LSTM model not loaded. Cannot predict rainfall trend.")
            return 0.0
        
        try:
            # Prepare input for LSTM (requires reshaping)
            # Typically LSTM expects shape: (batch_size, timesteps, features)
            data_array = np.array(historical_data).reshape(1, -1, 1)
            
            # Predict
            prediction = self.lstm_model.predict(data_array, verbose=0)
            
            return float(prediction[0][0])
            
        except Exception as e:
            print(f"⚠️ ERROR during LSTM prediction: {e}")
            return 0.0
    
    def is_model_ready(self):
        """
        Check if the Random Forest model is loaded and ready.
        
        Returns:
            bool: True if model is loaded
        """
        return self.rf_model is not None
