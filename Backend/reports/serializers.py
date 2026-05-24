from rest_framework import serializers
from .models import IncidentReport, SafetyStatus
from regions.models import Region


class IncidentReportSerializer(serializers.ModelSerializer):
    """
    Serializer for incident reports.
    """
    user_name = serializers.CharField(source='user.username', read_only=True)
    region_name = serializers.CharField(source='region.name', read_only=True)
    region_district = serializers.CharField(source='region.district', read_only=True)
    
    class Meta:
        model = IncidentReport
        fields = [
            'id', 'user', 'user_name', 'region', 'region_name', 'region_district',
            'description', 'image', 'timestamp', 'is_verified'
        ]
        read_only_fields = ['id', 'user', 'timestamp', 'is_verified', 'user_name', 'region_name', 'region_district']


class SafetyStatusSerializer(serializers.ModelSerializer):
    """
    Serializer for safety status updates.
    """
    user_name = serializers.CharField(source='user.username', read_only=True)
    region_name = serializers.CharField(source='region.name', read_only=True)
    
    class Meta:
        model = SafetyStatus
        fields = ['id', 'user', 'user_name', 'region', 'region_name', 'is_safe', 'last_marked_at']
        read_only_fields = ['id', 'user', 'last_marked_at', 'user_name', 'region_name']
