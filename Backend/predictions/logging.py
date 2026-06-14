from predictions.models import PredictionLog


def log_prediction(region, risk_score, rainfall_mm=None, soil_moisture=None):
    """
    Persist one prediction result for admin history and analytics.
    Logging must never break the prediction response path.
    """
    try:
        return PredictionLog.objects.create(
            region=region,
            risk_score=float(risk_score),
            rainfall_mm=rainfall_mm,
            soil_moisture=soil_moisture,
        )
    except Exception as exc:
        print(f"Prediction logging failed for {region}: {exc}")
        return None
