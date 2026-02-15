from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    """Admin interface for custom User model."""
    
    list_display = ['username', 'email', 'role', 'phone_number', 'is_staff', 'date_joined']
    list_filter = ['role', 'is_staff', 'is_superuser', 'is_active']
    search_fields = ['username', 'email', 'phone_number']
    
    fieldsets = UserAdmin.fieldsets + (
        ('HillSafe AI Info', {
            'fields': ('role', 'phone_number'),
        }),
    )
    
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('HillSafe AI Info', {
            'fields': ('role', 'phone_number'),
        }),
    )


from .models import DeviceToken

@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    """Admin interface for Firebase device tokens."""
    list_display = ['id', 'user', 'get_token_preview', 'created_at']
    list_filter = ['created_at']
    search_fields = ['token', 'user__username']
    readonly_fields = ['created_at']
    
    def get_token_preview(self, obj):
        """Show first 40 characters of token"""
        return f"{obj.token[:40]}..." if len(obj.token) > 40 else obj.token
    get_token_preview.short_description = 'Token'
