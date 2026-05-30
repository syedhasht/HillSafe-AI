from django.conf import settings
from django.db import models


class SavedSafetyTip(models.Model):
    """
    A safety guideline saved/bookmarked by a resident.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='saved_safety_tips',
    )
    tip_id = models.CharField(max_length=80)
    tip_title = models.CharField(max_length=180)
    tip_description = models.TextField()
    saved_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} saved {self.tip_title}"

    class Meta:
        verbose_name = 'Saved Safety Tip'
        verbose_name_plural = 'Saved Safety Tips'
        ordering = ['-saved_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'tip_id'],
                name='unique_saved_safety_tip_per_user',
            ),
        ]


class EmergencyContact(models.Model):
    """
    Emergency contact displayed in the mobile app.
    """

    name = models.CharField(max_length=120)
    number = models.CharField(max_length=30)
    description = models.CharField(max_length=180, blank=True)
    icon = models.CharField(max_length=40, blank=True)
    sort_order = models.PositiveSmallIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.number})"

    class Meta:
        verbose_name = 'Emergency Contact'
        verbose_name_plural = 'Emergency Contacts'
        ordering = ['sort_order', 'name']
