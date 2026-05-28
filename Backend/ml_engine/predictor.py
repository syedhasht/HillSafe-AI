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

os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '2')
os.environ.setdefault('TF_ENABLE_ONEDNN_OPTS', '0')

import joblib
import numpy as np
import pandas as pd
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

        models_dir = os.path.join(settings.BASE_DIR, 'ml_engine', 'models')
        print(f"Loading ML models from: {models_dir}")

        self.rf_model = None
        self.lstm_model = None
        self.scaler = None

        try:
            rf_path = os.path.join(models_dir, 'landslide_rf_model.pkl')
            self.rf_model = joblib.load(rf_path)
            print("Random Forest model loaded successfully")
        except FileNotFoundError:
            print(f"WARNING: landslide_rf_model.pkl not found at {rf_path}")
        except Exception as exc:
            print(f"ERROR loading Random Forest model: {exc}")

        try:
            import tensorflow as tf

            lstm_path = os.path.join(models_dir, 'rainfall_lstm.h5')
            self.lstm_model = tf.keras.models.load_model(
                lstm_path,
                compile=False,
                safe_mode=False,
            )
            print("LSTM model loaded successfully")
        except FileNotFoundError:
            print(f"WARNING: rainfall_lstm.h5 not found at {lstm_path}")
        except Exception as exc:
            print(f"ERROR loading LSTM model: {exc}")

        try:
            scaler_path = os.path.join(models_dir, 'weather_scaler.pkl')
            self.scaler = joblib.load(scaler_path)
            print("Weather scaler loaded successfully")
        except FileNotFoundError:
            print(f"WARNING: weather_scaler.pkl not found at {scaler_path}")
        except Exception as exc:
            print(f"ERROR loading scaler: {exc}")

        HillSafePredictor._models_loaded = True
        print("ML Engine initialization complete")

    def predict_risk(self, rainfall, slope, soil, lithology, terrain_features=None):
        """
        Predict landslide risk using the Random Forest model.

        Args:
            rainfall (float): Precipitation category code.
            slope (float): Slope category code.
            soil (float): Soil type index. Kept for API compatibility.
            lithology (int): Lithology category code.
            terrain_features (dict): Optional RF feature-code overrides.

        Returns:
            float: Risk probability (0.0 to 1.0)
        """
        if self.rf_model is None:
            print("Random Forest model not loaded. Returning default risk.")
            return 0.0

        try:
            feature_defaults = {
                'Aspect': 3,
                'Curvature': 2,
                'Earthquake': 2,
                'Elevation': 2,
                'Flow': 2,
                'NDVI': 2,
                'NDWI': 2,
                'Plan': 2,
                'Profile': 2,
            }
            if terrain_features:
                feature_defaults.update({
                    key: terrain_features[key]
                    for key in feature_defaults
                    if key in terrain_features and terrain_features[key] is not None
                })

            feature_names = [
                'aspect',
                'curvature',
                'earthquake',
                'elevation',
                'flow',
                'lithology',
                'ndvi',
                'ndwi',
                'plan',
                'precipitation',
                'profile',
                'slope',
            ]
            feature_values = [[
                feature_defaults['Aspect'],
                feature_defaults['Curvature'],
                feature_defaults['Earthquake'],
                feature_defaults['Elevation'],
                feature_defaults['Flow'],
                float(lithology),
                feature_defaults['NDVI'],
                feature_defaults['NDWI'],
                feature_defaults['Plan'],
                float(rainfall),
                feature_defaults['Profile'],
                float(slope),
            ]]
            features = pd.DataFrame(feature_values, columns=feature_names)

            if (
                self.scaler is not None
                and hasattr(self.scaler, 'n_features_in_')
                and self.scaler.n_features_in_ == features.shape[1]
            ):
                features = pd.DataFrame(
                    self.scaler.transform(features),
                    columns=feature_names,
                )

            probabilities = self.rf_model.predict_proba(features)
            risk_score = float(probabilities[0][1])

            print(
                f"Prediction: rainfall={rainfall}, slope={slope}, "
                f"soil={soil}, lithology={lithology} -> risk={risk_score:.3f}"
            )
            return risk_score

        except Exception as exc:
            print(f"ERROR during prediction: {exc}")
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
            print("LSTM model not loaded. Cannot predict rainfall trend.")
            return 0.0

        try:
            data_array = np.array(historical_data).reshape(1, -1, 1)
            prediction = self.lstm_model.predict(data_array, verbose=0)
            return float(prediction[0][0])

        except Exception as exc:
            print(f"ERROR during LSTM prediction: {exc}")
            return 0.0

    def is_model_ready(self):
        """
        Check if the Random Forest model is loaded and ready.

        Returns:
            bool: True if model is loaded
        """
        return self.rf_model is not None
