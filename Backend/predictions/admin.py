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

    def save_model(self, request, obj, form, change):
        """
        Override save_model to:
          1. When rainfall_mm is changed, re-run the ML pipeline to recalculate
             the risk score and update both the PredictionLog and the associated
             Region's current_risk_score.
          2. Persist the updated PredictionLog.
          3. Sync the risk score to the associated Region and delegate to RegionAdmin's
             alert logic so that a critical alert and push notification are sent if
             the risk score crosses the CRITICAL_THRESHOLD.
        """
        from regions.models import Region
        from regions.admin import _maybe_send_critical_alert
        from data_ingestion.map_updates import send_authority_map_update

        region = None
        old_region_risk = 0.0
        if obj.region_id:
            try:
                region = Region.objects.get(pk=obj.region_id)
                old_region_risk = float(region.current_risk_score or 0)
            except Region.DoesNotExist:
                pass

        # Detect whether rainfall_mm was changed by comparing with DB value.
        old_rainfall = None
        if change and obj.pk:
            try:
                old_rainfall = PredictionLog.objects.values_list(
                    'rainfall_mm', flat=True
                ).get(pk=obj.pk)
            except PredictionLog.DoesNotExist:
                pass

        should_recalculate = False
        if not change:
            # New prediction log: calculate if rainfall is provided
            should_recalculate = obj.rainfall_mm is not None
        else:
            # Existing log: calculate if rainfall is updated or was previously unset
            if obj.rainfall_mm is not None:
                if old_rainfall is None:
                    should_recalculate = True
                else:
                    should_recalculate = float(old_rainfall) != float(obj.rainfall_mm)

        if should_recalculate and region:
            # Re-run the ML pipeline with the new rainfall value so that
            # risk_score reflects the updated weather input.
            try:
                from ml_engine.predictor import HillSafePredictor
                from ml_engine.views import (
                    _precipitation_code,
                    _get_or_create_terrain_sample,
                    _terrain_defaults_from_region,
                )

                predictor = HillSafePredictor()
                if predictor.is_model_ready():
                    terrain_defaults = _terrain_defaults_from_region(region)
                    terrain_sample, _ = _get_or_create_terrain_sample(
                        region.latitude, region.longitude
                    )
                    terrain = {
                        'slope':     terrain_sample.slope_code     or terrain_defaults['slope'],
                        'soil':      terrain_sample.soil_code      or terrain_defaults['soil'],
                        'lithology': terrain_sample.lithology_code or terrain_defaults['lithology'],
                        'elevation': terrain_sample.elevation_code or terrain_defaults['elevation'],
                        'ndvi':      terrain_sample.ndvi_code      or terrain_defaults['ndvi'],
                        'ndwi':      terrain_sample.ndwi_code      or terrain_defaults['ndwi'],
                    }

                    new_risk_score = predictor.predict_risk(
                        _precipitation_code(float(obj.rainfall_mm)),
                        terrain['slope'],
                        terrain['soil'],
                        terrain['lithology'],
                        terrain_features={
                            'Elevation': terrain['elevation'],
                            'NDVI':      terrain['ndvi'],
                            'NDWI':      terrain['ndwi'],
                        },
                    )

                    # Update the log's risk_score to match recalculated value.
                    obj.risk_score = new_risk_score
                    print(
                        f"[PredictionLogAdmin] Recalculated risk for {region.name}: "
                        f"rainfall {old_rainfall}→{obj.rainfall_mm} mm, "
                        f"risk {old_region_risk:.2f}→{new_risk_score:.2f}"
                    )
                else:
                    print(
                        "[PredictionLogAdmin] ML model not ready. "
                        "Skipping risk recalculation."
                    )

            except Exception as exc:
                print(f"[PredictionLogAdmin] Error during risk recalculation: {exc}")

        # Always sync the prediction log's risk score to the associated Region model
        if region:
            region.current_risk_score = obj.risk_score
            region.save(update_fields=['current_risk_score', 'updated_at', 'last_updated'])

            # Fire critical alert / push notification if threshold crossed.
            _maybe_send_critical_alert(region, old_region_risk)

            # Trigger map update notification to refresh frontend dashboards/maps
            try:
                send_authority_map_update('prediction_saved')
            except Exception as exc:
                print(f"[PredictionLogAdmin] Error triggering map update: {exc}")

        # Persist the PredictionLog record itself.
        super().save_model(request, obj, form, change)
