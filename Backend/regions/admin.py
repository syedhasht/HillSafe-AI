from django.contrib import admin
from .models import Region, TerrainSample


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    """Admin interface for Region model."""
    
    list_display = ['name', 'district', 'latitude', 'longitude', 'current_risk_score', 'updated_at']
    list_filter = ['district']
    search_fields = ['name', 'district']
    ordering = ['-current_risk_score', 'name']
    
    fieldsets = (
        ('Location Information', {
            'fields': ('name', 'district', 'latitude', 'longitude'),
        }),
        ('Risk Assessment', {
            'fields': ('current_risk_score',),
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(TerrainSample)
class TerrainSampleAdmin(admin.ModelAdmin):
    """Admin interface for persisted terrain lookups."""

    list_display = [
        'latitude_key',
        'longitude_key',
        'elevation_m',
        'slope_degrees',
        'soil_type',
        'data_quality',
        'updated_at',
    ]
    list_filter = ['data_quality', 'elevation_source', 'soil_source']
    search_fields = ['latitude_key', 'longitude_key', 'soil_type']
    readonly_fields = ['created_at', 'updated_at']
