from django.db import models
from django.conf import settings
from regions.models import Region


class IncidentReport(models.Model):
    """
    Model for community-reported incidents.
    Allows residents to report landslides, hazards, or other incidents.
    """

    REVIEW_STATUS_CHOICES = [
        ('PENDING', 'Pending Review'),
        ('APPROVED', 'Approved'),
        ('DECLINED', 'Declined'),
    ]

    HAZARD_LEVEL_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
        ('CRITICAL', 'Critical'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='incident_reports',
        help_text="User who reported the incident"
    )
    
    region = models.ForeignKey(
        Region,
        on_delete=models.SET_NULL,
        related_name='incident_reports',
        null=True,
        blank=True,
        help_text="Region where incident occurred"
    )
    
    description = models.TextField(
        help_text="Detailed description of the incident"
    )

    latitude = models.FloatField(
        null=True,
        blank=True,
        help_text="Latitude where the incident was reported"
    )

    longitude = models.FloatField(
        null=True,
        blank=True,
        help_text="Longitude where the incident was reported"
    )

    area_name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Human-readable incident location"
    )

    report_radius_km = models.FloatField(
        default=10.0,
        help_text="Approximate radius covered by this report"
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

    review_status = models.CharField(
        max_length=20,
        choices=REVIEW_STATUS_CHOICES,
        default='PENDING',
    )

    hazard_level = models.CharField(
        max_length=20,
        choices=HAZARD_LEVEL_CHOICES,
        null=True,
        blank=True,
        help_text="Authority-assigned level, available only for approved reports",
    )

    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name='reviewed_incident_reports',
        null=True,
        blank=True,
    )

    reviewed_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        place = self.region.name if self.region else self.area_name or 'Your location'
        return f"{self.user.username} - {place} ({self.timestamp.strftime('%Y-%m-%d %H:%M')})"
    
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

    latitude = models.FloatField(
        null=True,
        blank=True,
        help_text="Latitude where the user marked themselves safe"
    )

    longitude = models.FloatField(
        null=True,
        blank=True,
        help_text="Longitude where the user marked themselves safe"
    )

    area_name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Human-readable area name for the check-in location"
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


class SOSRequest(models.Model):
    """
    Emergency SOS request sent by a resident from the mobile app.
    """

    STATUS_CHOICES = [
        ('NEEDS_HELP', 'Needs Help'),
        ('ACKNOWLEDGED', 'Acknowledged'),
        ('RESOLVED', 'Resolved'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sos_requests',
        help_text="User who sent the SOS request"
    )

    region = models.ForeignKey(
        Region,
        on_delete=models.SET_NULL,
        related_name='sos_requests',
        null=True,
        blank=True,
        help_text="Nearest/current risk area for this SOS request"
    )

    name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    area_name = models.CharField(max_length=255, blank=True)
    risk_level = models.CharField(max_length=20, blank=True)
    risk_score = models.FloatField(null=True, blank=True)
    message = models.TextField(default='Emergency SOS. User needs immediate help.')
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='NEEDS_HELP',
    )
    timestamp = models.DateTimeField(auto_now_add=True)
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        region_name = self.region.name if self.region else self.area_name or 'Unknown area'
        return f"SOS from {self.name} - {region_name}"

    class Meta:
        verbose_name = "SOS Request"
        verbose_name_plural = "SOS Requests"
        ordering = ['-timestamp']
