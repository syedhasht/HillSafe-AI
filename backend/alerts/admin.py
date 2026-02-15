from django.contrib import admin
from .models import Alert


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    """Admin interface for Alert model."""
    
    list_display = ['region', 'severity', 'is_active', 'timestamp', 'message_preview']
    list_filter = ['severity', 'is_active', 'timestamp']
    search_fields = ['message', 'region__name']
    ordering = ['-timestamp']
    date_hierarchy = 'timestamp'
    
    fieldsets = (
        ('Alert Information', {
            'fields': ('region', 'severity', 'message'),
        }),
        ('Status', {
            'fields': ('is_active', 'resolved_at'),
        }),
    )
    
    readonly_fields = ['timestamp']
    
    def message_preview(self, obj):
        """Show first 50 characters of message."""
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    message_preview.short_description = 'Message Preview'
    
    actions = ['mark_as_resolved', 'mark_as_active']
    
    def mark_as_resolved(self, request, queryset):
        """Mark selected alerts as resolved."""
        from django.utils import timezone
        queryset.update(is_active=False, resolved_at=timezone.now())
    mark_as_resolved.short_description = "Mark selected alerts as resolved"
    
    def mark_as_active(self, request, queryset):
        """Mark selected alerts as active."""
        queryset.update(is_active=True, resolved_at=None)
    mark_as_active.short_description = "Mark selected alerts as active"
