from django.contrib import admin
from .models import IncidentReport, SafetyStatus


@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    """
    Admin interface for incident reports.
    """
    list_display = ['id', 'user', 'region', 'get_description_preview', 'timestamp', 'is_verified']
    list_filter = ['is_verified', 'region', 'timestamp']
    search_fields = ['user__username', 'region__name', 'description']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Report Information', {
            'fields': ('user', 'region', 'description', 'image')
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
    list_display = ['id', 'user', 'region', 'is_safe', 'last_marked_at']
    list_filter = ['is_safe', 'region', 'last_marked_at']
    search_fields = ['user__username', 'region__name']
    readonly_fields = ['last_marked_at']
    date_hierarchy = 'last_marked_at'
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'region')
        }),
        ('Status', {
            'fields': ('is_safe', 'last_marked_at')
        }),
    )
