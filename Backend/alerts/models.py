from django.db import models
from regions.models import Region


class Alert(models.Model):
    """
    Alert model for landslide warnings and notifications.
    Links to specific regions and tracks severity levels.
    """
    
    SEVERITY_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
        ('CRITICAL', 'Critical'),
    ]
    
    region = models.ForeignKey(
        Region,
        on_delete=models.CASCADE,
        related_name='alerts',
        help_text="Region this alert is issued for"
    )
    
    severity = models.CharField(
        max_length=10,
        choices=SEVERITY_CHOICES,
        default='LOW',
        help_text="Alert severity level"
    )

    affected_population = models.IntegerField(
        default=0,
        help_text="Estimated number of people affected"
    )
    
    message = models.TextField(
        help_text="Detailed alert message or warning"
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this alert is currently active"
    )
    
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text="When the alert was created"
    )
    
    resolved_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the alert was resolved/deactivated"
    )
    
    def __str__(self):
        status = "ACTIVE" if self.is_active else "RESOLVED"
        return f"[{status}] {self.severity} Alert for {self.region.name} at {self.timestamp}"
    
    class Meta:
        verbose_name = "Alert"
        verbose_name_plural = "Alerts"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['-timestamp']),
            models.Index(fields=['is_active', '-timestamp']),
        ]
