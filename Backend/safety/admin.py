from django.contrib import admin

from .models import EmergencyContact, SavedSafetyTip


@admin.register(SavedSafetyTip)
class SavedSafetyTipAdmin(admin.ModelAdmin):
    list_display = ('user', 'tip_title', 'saved_at')
    list_filter = ('saved_at',)
    search_fields = ('user__username', 'tip_id', 'tip_title')


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ('name', 'number', 'sort_order', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name', 'number')
