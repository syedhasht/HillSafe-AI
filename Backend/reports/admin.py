from django.contrib import admin
from .models import IncidentReport, SafetyStatus, SOSRequest


@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    """
    Admin interface for incident reports.
    """
    list_display = ['id', 'user', 'region', 'area_name', 'report_radius_km', 'get_description_preview', 'timestamp', 'is_verified']
    list_filter = ['is_verified', 'region', 'timestamp']
    search_fields = ['user__username', 'region__name', 'description']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Report Information', {
            'fields': ('user', 'region', 'description', 'image')
        }),
        ('Location', {
            'fields': ('area_name', 'latitude', 'longitude', 'report_radius_km')
        }),
        ('Status', {
            'fields': ('is_verified', 'timestamp')
        }),
    )
    
    def get_description_preview(self, obj):
        """Show first 50 characters of description"""
        return obj.description[:50] + '...' if len(obj.description) > 50 else obj.description
    get_description_preview.short_description = 'Description'
    
    actions = ['mark_as_verified', 'mark_as_unverified']
    
    def mark_as_verified(self, request, queryset):
        """Mark selected reports as verified"""
        count = queryset.update(is_verified=True)
        self.message_user(request, f'{count} report(s) marked as verified.')
    mark_as_verified.short_description = 'Mark selected reports as verified'
    
    def mark_as_unverified(self, request, queryset):
        """Mark selected reports as unverified"""
        count = queryset.update(is_verified=False)
        self.message_user(request, f'{count} report(s) marked as unverified.')
    mark_as_unverified.short_description = 'Mark selected reports as unverified'


@admin.register(SafetyStatus)
class SafetyStatusAdmin(admin.ModelAdmin):
    """
    Admin interface for safety statuses.
    """
    list_display = ['id', 'user', 'region', 'area_name', 'latitude', 'longitude', 'is_safe', 'last_marked_at']
    list_filter = ['is_safe', 'region', 'last_marked_at']
    search_fields = ['user__username', 'region__name', 'area_name']
    readonly_fields = ['last_marked_at']
    date_hierarchy = 'last_marked_at'
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'region')
        }),
        ('Location', {
            'fields': ('area_name', 'latitude', 'longitude')
        }),
        ('Status', {
            'fields': ('is_safe', 'last_marked_at')
        }),
    )


@admin.register(SOSRequest)
class SOSRequestAdmin(admin.ModelAdmin):
    """Admin interface for emergency SOS requests."""
    list_display = ['id', 'name', 'phone_number', 'region', 'risk_level', 'status', 'timestamp']
    list_filter = ['status', 'risk_level', 'region', 'timestamp']
    search_fields = ['name', 'phone_number', 'area_name', 'region__name', 'message']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
