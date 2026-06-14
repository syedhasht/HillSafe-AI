from rest_framework import serializers
from .models import IncidentReport, SafetyStatus
from regions.models import Region


class IncidentReportSerializer(serializers.ModelSerializer):
    """
    Serializer for incident reports.
    """
    user_name = serializers.CharField(source='user.username', read_only=True)
    phone_number = serializers.SerializerMethodField()
    region_name = serializers.SerializerMethodField()
    region_district = serializers.SerializerMethodField()
    reviewer_name = serializers.CharField(source='reviewed_by.username', read_only=True)
    
    class Meta:
        model = IncidentReport
        fields = [
            'id', 'user', 'user_name', 'phone_number', 'region', 'region_name', 'region_district',
            'description', 'latitude', 'longitude', 'area_name', 'image',
            'report_radius_km', 'timestamp', 'is_verified', 'review_status',
            'hazard_level', 'reviewer_name', 'reviewed_at', 'expires_at',
        ]
        read_only_fields = [
            'id', 'user', 'timestamp', 'is_verified', 'user_name',
            'region_name', 'region_district', 'phone_number', 'review_status',
            'hazard_level', 'reviewer_name', 'reviewed_at', 'expires_at',
        ]

    def get_phone_number(self, obj):
        request = self.context.get('request')
        if request and getattr(request.user, 'role', '').upper() == 'AUTHORITY':
            return obj.user.phone_number
        return None

    def get_region_name(self, obj):
        if obj.region:
            return obj.region.name
        return obj.area_name or 'Your Location'

    def get_region_district(self, obj):
        if obj.region:
            return obj.region.district
        return '10 km radius'


class SafetyStatusSerializer(serializers.ModelSerializer):
    """
    Serializer for safety status updates.
    """
    user_name = serializers.CharField(source='user.username', read_only=True)
    phone_number = serializers.SerializerMethodField()
    region_name = serializers.CharField(source='region.name', read_only=True)
    region_district = serializers.CharField(source='region.district', read_only=True)
    can_mark_again = serializers.SerializerMethodField()
    next_allowed_at = serializers.SerializerMethodField()
    seconds_until_next_mark = serializers.SerializerMethodField()

    COOLDOWN_MINUTES = 30
    
    class Meta:
        model = SafetyStatus
        fields = [
            'id',
            'user',
            'user_name',
            'phone_number',
            'region',
            'region_name',
            'region_district',
            'is_safe',
            'latitude',
            'longitude',
            'area_name',
            'last_marked_at',
            'can_mark_again',
            'next_allowed_at',
            'seconds_until_next_mark',
        ]
        read_only_fields = [
            'id',
            'user',
            'last_marked_at',
            'user_name',
            'phone_number',
            'region_name',
            'region_district',
            'can_mark_again',
            'next_allowed_at',
            'seconds_until_next_mark',
        ]

    def get_phone_number(self, obj):
        request = self.context.get('request')
        if request and getattr(request.user, 'role', '').upper() == 'AUTHORITY':
            return obj.user.phone_number
        return None

    def _next_allowed_at(self, obj):
        from datetime import timedelta

        return obj.last_marked_at + timedelta(minutes=self.COOLDOWN_MINUTES)

    def get_next_allowed_at(self, obj):
        return self._next_allowed_at(obj)

    def get_can_mark_again(self, obj):
        from django.utils import timezone

        return timezone.now() >= self._next_allowed_at(obj)

    def get_seconds_until_next_mark(self, obj):
        from django.utils import timezone

        remaining = self._next_allowed_at(obj) - timezone.now()
        return max(0, int(remaining.total_seconds()))
