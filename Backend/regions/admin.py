from django.contrib import admin
from .models import Region


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
