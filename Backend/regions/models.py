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


class TerrainSample(models.Model):
    """
    Persisted terrain data for a rounded location.
    External terrain APIs are slow/rate-limited, so the backend stores the
    resolved values and reuses them for nearby requests.
    """

    latitude_key = models.DecimalField(max_digits=8, decimal_places=4)
    longitude_key = models.DecimalField(max_digits=9, decimal_places=4)
    requested_latitude = models.FloatField()
    requested_longitude = models.FloatField()

    elevation_m = models.FloatField(null=True, blank=True)
    slope_degrees = models.FloatField(null=True, blank=True)
    elevation_code = models.IntegerField(default=2)
    slope_code = models.IntegerField(default=2)

    soil_type = models.CharField(max_length=80, blank=True, default="")
    soil_code = models.IntegerField(default=2)
    clay_percent = models.FloatField(null=True, blank=True)
    sand_percent = models.FloatField(null=True, blank=True)
    silt_percent = models.FloatField(null=True, blank=True)

    lithology_type = models.CharField(max_length=80, blank=True, default="unknown")
    lithology_code = models.IntegerField(default=2)
    ndvi_code = models.IntegerField(default=2)
    ndwi_code = models.IntegerField(default=2)

    elevation_source = models.CharField(max_length=80, blank=True, default="")
    soil_source = models.CharField(max_length=80, blank=True, default="")
    data_quality = models.CharField(max_length=40, default="partial")
    fetch_errors = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Terrain {self.latitude_key}, {self.longitude_key} ({self.data_quality})"

    class Meta:
        verbose_name = "Terrain Sample"
        verbose_name_plural = "Terrain Samples"
        unique_together = ["latitude_key", "longitude_key"]
        indexes = [
            models.Index(fields=["latitude_key", "longitude_key"]),
        ]
