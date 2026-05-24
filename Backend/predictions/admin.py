from django.contrib import admin
from .models import PredictionLog


@admin.register(PredictionLog)
class PredictionLogAdmin(admin.ModelAdmin):
    """Admin interface for PredictionLog model."""
    
    list_display = ['region', 'risk_score', 'rainfall_mm', 'soil_moisture', 'timestamp']
    list_filter = ['region', 'timestamp']
    search_fields = ['region__name']
    ordering = ['-timestamp']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Prediction Information', {
            'fields': ('region', 'risk_score'),
        }),
        ('Weather Data', {
            'fields': ('rainfall_mm', 'soil_moisture'),
        }),
    )
    
    readonly_fields = ['timestamp']
