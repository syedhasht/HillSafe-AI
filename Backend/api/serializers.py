from rest_framework import serializers
from accounts.models import User
from regions.models import Region
from alerts.models import Alert


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for User model.
    Returns basic user information for API responses.
    """
    
    class Meta:
        model = User
        fields = ['id', 'username', 'role']
        read_only_fields = ['id']


class RegionSerializer(serializers.ModelSerializer):
    """
    Serializer for Region model.
    Returns region details including location and risk score.
    """
    
    class Meta:
        model = Region
        fields = [
            'id',
            'name',
            'district',
            'latitude',
            'longitude',
            'current_risk_score',
            'is_critical_zone',
            'danger_radius_km',
            'warning_radius_km',
            'last_updated',
        ]
        read_only_fields = ['id', 'last_updated']


class AlertSerializer(serializers.ModelSerializer):
    """
    Serializer for Alert model.
    Includes nested region information for complete alert details.
    """
    region_name = serializers.CharField(source='region.name', read_only=True)
    region_district = serializers.CharField(source='region.district', read_only=True)
    region_lat = serializers.FloatField(source='region.latitude', read_only=True)
    region_lng = serializers.FloatField(source='region.longitude', read_only=True)
    
    class Meta:
        model = Alert
        fields = ['id', 'severity', 'message', 'timestamp', 'region', 'region_name', 'region_district', 'region_lat', 'region_lng', 'affected_population']
        read_only_fields = ['id', 'timestamp']
