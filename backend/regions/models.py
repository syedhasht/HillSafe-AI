from django.db import models


class Region(models.Model):
    """
    Region model representing geographical areas monitored by HillSafe AI.
    Stores location data and current risk assessment scores.
    """
    
    name = models.CharField(
        max_length=200,
        help_text="Name of the region (e.g., 'Murree Hills')"
    )
    
    district = models.CharField(
        max_length=200,
        help_text="District name (e.g., 'Rawalpindi')"
    )
    
    latitude = models.FloatField(
        help_text="Geographical latitude coordinate"
    )
    
    longitude = models.FloatField(
        help_text="Geographical longitude coordinate"
    )
    
    current_risk_score = models.FloatField(
        default=0.0,
        help_text="Current landslide risk score (0.0 to 1.0)"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_updated = models.DateTimeField(
        auto_now=True,
        help_text="Last time weather data was fetched for this region"
    )
    
    def __str__(self):
        return f"{self.name}, {self.district} (Risk: {self.current_risk_score:.2f})"
    
    class Meta:
        verbose_name = "Region"
        verbose_name_plural = "Regions"
        ordering = ['-current_risk_score', 'name']
        unique_together = ['name', 'district']
