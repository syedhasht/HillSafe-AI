from django.db import models
from django.conf import settings
from regions.models import Region


class IncidentReport(models.Model):
    """
    Model for community-reported incidents.
    Allows residents to report landslides, hazards, or other incidents.
    """
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='incident_reports',
        help_text="User who reported the incident"
    )
    
    region = models.ForeignKey(
        Region,
        on_delete=models.CASCADE,
        related_name='incident_reports',
        help_text="Region where incident occurred"
    )
    
    description = models.TextField(
        help_text="Detailed description of the incident"
    )
    
    image = models.ImageField(
        upload_to='incident_images/',
        null=True,
        blank=True,
        help_text="Optional photo evidence"
    )
    
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text="When the report was submitted"
    )
    
    is_verified = models.BooleanField(
        default=False,
        help_text="Whether authorities have verified this report"
    )
    
    def __str__(self):
        return f"{self.user.username} - {self.region.name} ({self.timestamp.strftime('%Y-%m-%d %H:%M')})"
    
    class Meta:
        verbose_name = "Incident Report"
        verbose_name_plural = "Incident Reports"
        ordering = ['-timestamp']


class SafetyStatus(models.Model):
    """
    Model for tracking user safety status in regions.
    Allows users to mark themselves as safe during emergencies.
    """
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='safety_statuses',
        help_text="User marking their safety status"
    )
    
    region = models.ForeignKey(
        Region,
        on_delete=models.CASCADE,
        related_name='safety_statuses',
        help_text="Region where user is located"
    )
    
    is_safe = models.BooleanField(
        default=True,
        help_text="Whether user has marked themselves as safe"
    )
    
    last_marked_at = models.DateTimeField(
        auto_now=True,
        help_text="Last time user updated their status"
    )
    
    def __str__(self):
        status = "Safe" if self.is_safe else "Not Safe"
        return f"{self.user.username} - {self.region.name}: {status}"
    
    class Meta:
        verbose_name = "Safety Status"
        verbose_name_plural = "Safety Statuses"
        ordering = ['-last_marked_at']
        unique_together = ['user', 'region']  # One status per user per region
