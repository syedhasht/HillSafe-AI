from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    """
    Custom User model for HillSafe AI.
    Extends Django's AbstractUser to add role and phone number fields.
    """
    
    ROLE_CHOICES = [
        ('AUTHORITY', 'Disaster Authority'),
        ('COMMUNITY', 'Community User'),
        ('ADMIN', 'System Admin'),
    ]

    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('ur', 'Urdu'),
    ]
    
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='COMMUNITY',
        help_text="User's role in the system"
    )
    
    phone_number = models.CharField(
        max_length=20,
        unique=True,
        help_text="User's unique contact phone number"
    )

    is_logged_in = models.BooleanField(
        default=False,
        help_text="Whether the user currently has an active app login"
    )

    language = models.CharField(
        max_length=2,
        choices=LANGUAGE_CHOICES,
        default='en',
        help_text="User's preferred app language"
    )

    dark_mode = models.BooleanField(
        default=False,
        help_text="Whether the user has dark mode enabled"
    )
    
    # Safety Status Fields
    is_safe = models.BooleanField(
        default=False,
        help_text="Whether user has marked themselves as safe"
    )
    
    safe_status_updated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When user last updated their safety status"
    )
    
    location_region = models.ForeignKey(
        'regions.Region',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='safe_users',
        help_text="User's current location region"
    )
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"
        ordering = ['-date_joined']


class ResidentProfile(models.Model):
    """
    Resident-specific login/profile record.
    Kept separate from authority profile data while still linking to auth user.
    """

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='resident_profile',
    )
    username = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, unique=True)
    email = models.EmailField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Resident: {self.username} ({self.phone_number})"

    class Meta:
        verbose_name = "Resident Login Profile"
        verbose_name_plural = "Resident Login Profiles"
        ordering = ['-updated_at']


class AuthorityProfile(models.Model):
    """
    Authority-specific login/profile record.
    Kept separate from resident login/profile data.
    """

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='authority_profile',
    )
    username = models.CharField(max_length=150, unique=True)
    phone_number = models.CharField(max_length=20, unique=True)
    email = models.EmailField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Authority: {self.username} ({self.phone_number})"

    class Meta:
        verbose_name = "Authority Login Profile"
        verbose_name_plural = "Authority Login Profiles"
        ordering = ['-updated_at']


class DeviceToken(models.Model):
    """
    Model for storing Firebase Cloud Messaging device tokens.
    Used to send push notifications to mobile devices.
    """
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='device_tokens',
        null=True,
        blank=True,
        help_text="User associated with this device (optional)"
    )
    
    token = models.CharField(
        max_length=255,
        unique=True,
        help_text="Firebase Cloud Messaging token"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When this token was registered"
    )
    
    def __str__(self):
        user_str = self.user.username if self.user else "Anonymous"
        return f"Device Token for {user_str} ({self.token[:20]}...)"
    
    class Meta:
        verbose_name = "Device Token"
        verbose_name_plural = "Device Tokens"
        ordering = ['-created_at']
