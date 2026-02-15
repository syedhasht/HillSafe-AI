from django.db import models
from regions.models import Region


class PredictionLog(models.Model):
    """
    Log of prediction calculations for landslide risk.
    Stores historical predictions for analysis and tracking.
    """
    
    region = models.ForeignKey(
        Region,
        on_delete=models.CASCADE,
        related_name='predictions',
        help_text="Region this prediction was made for"
    )
    
    risk_score = models.FloatField(
        help_text="Calculated risk score (0.0 to 1.0)"
    )
    
    rainfall_mm = models.FloatField(
        null=True,
        blank=True,
        help_text="Rainfall data used in calculation"
    )
    
    soil_moisture = models.FloatField(
        null=True,
        blank=True,
        help_text="Soil moisture data used in calculation"
    )
    
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text="When the prediction was made"
    )
    
    def __str__(self):
        return f"Prediction for {self.region.name} at {self.timestamp} - Risk: {self.risk_score:.2f}"
    
    class Meta:
        verbose_name = "Prediction Log"
        verbose_name_plural = "Prediction Logs"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['-timestamp']),
            models.Index(fields=['region', '-timestamp']),
        ]
