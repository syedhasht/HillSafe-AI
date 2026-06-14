from django.contrib import admin
from django.utils import timezone
from .models import Region, TerrainSample


# ---------------------------------------------------------------------------
# Threshold above which a region is considered critically dangerous.
# Matches the threshold used in data_ingestion/views.py
# ---------------------------------------------------------------------------
CRITICAL_THRESHOLD = 0.7


def _maybe_send_critical_alert(region, old_risk_score):
    """
    If the region's current_risk_score just crossed CRITICAL_THRESHOLD,
    create an Alert record and send a push notification to all registered
    devices.  Runs in a background thread so the admin save does not stall.

    Args:
        region: The Region instance that was just saved (new risk score).
        old_risk_score: The risk score value before the admin save.
    """
    new_score = float(region.current_risk_score or 0)
    old_score = float(old_risk_score or 0)

    # Only act when crossing into (or staying in) the critical band from a
    # non-critical value, i.e. the score rose into the danger zone.
    if new_score < CRITICAL_THRESHOLD or old_score >= CRITICAL_THRESHOLD:
        return

    import threading

    def _bg():
        try:
            from alerts.models import Alert
            from data_ingestion.services import send_push_notification

            # Check whether there is already an active alert for this region
            # to avoid spamming duplicate alerts.
            if Alert.objects.filter(region=region, is_active=True).exists():
                print(
                    f"[RegionAdmin] Active alert already exists for {region.name}. "
                    "Skipping duplicate alert creation."
                )
                return

            Alert.objects.create(
                region=region,
                severity='CRITICAL',
                message=(
                    f"Risk score for {region.name} has been manually raised to "
                    f"{new_score:.0%} by an administrator. "
                    "Landslide risk is critically high. Please take necessary precautions."
                ),
                is_active=True,
            )
            print(
                f"[RegionAdmin] CRITICAL alert created for {region.name} "
                f"(score {old_score:.2f} → {new_score:.2f})."
            )

            send_push_notification(region.name, new_score)

        except Exception as exc:
            print(f"[RegionAdmin] Error sending critical alert for {region.name}: {exc}")

    threading.Thread(target=_bg, daemon=True).start()


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    """Admin interface for Region model."""

    list_display = [
        'name',
        'district',
        'latitude',
        'longitude',
        'current_risk_score',
        'is_critical_zone',
        'danger_radius_km',
        'warning_radius_km',
        'updated_at',
    ]
    list_filter = ['district', 'is_critical_zone']
    search_fields = ['name', 'district']
    ordering = ['-current_risk_score', 'name']

    fieldsets = (
        ('Location Information', {
            'fields': ('name', 'district', 'latitude', 'longitude'),
        }),
        ('Risk Assessment', {
            'fields': ('current_risk_score', 'is_critical_zone', 'danger_radius_km', 'warning_radius_km'),
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def save_model(self, request, obj, form, change):
        """
        Override save_model to:
          1. Capture the old risk score before saving.
          2. Persist the new values.
          3. If the risk score just crossed the CRITICAL_THRESHOLD, fire an
             immediate Alert and push notification in a background thread.
        """
        # Fetch the pre-save risk score from the database (if this is an update).
        old_risk_score = 0.0
        if change and obj.pk:
            try:
                old_risk_score = float(
                    Region.objects.values_list('current_risk_score', flat=True)
                    .get(pk=obj.pk)
                )
            except Region.DoesNotExist:
                old_risk_score = 0.0

        # Persist the updated region first.
        super().save_model(request, obj, form, change)

        # After saving, check whether we need to send a critical alert.
        _maybe_send_critical_alert(obj, old_risk_score)


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
