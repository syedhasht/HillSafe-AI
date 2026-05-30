"""
Analytics endpoint — serves real data from the DB.

GET /api/analytics/
  ?period=24hours|7days|30days
  ?region_id=<int>   (optional)

Returns:
  risk_trend         — daily avg risk score (from PredictionLog if available,
                       else current Region.current_risk_score replicated)
  alerts_per_day     — count of real alerts created each day (from Alert table)
  critical_count     — regions with risk >= 0.70
  high_count         — regions with risk 0.50-0.70
  medium_count       — regions with risk 0.30-0.50
  low_count          — regions with risk < 0.30
  total_regions      — total monitored regions
  total_alerts       — total alerts in the period
  alert_severity_breakdown — {CRITICAL, HIGH, MEDIUM, LOW} counts
  regions_detail     — per-region name + risk + district
  period_days        — number of days in period
  labels             — date label strings for charts
"""

from django.db.models import Avg, Count
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status

from regions.models import Region
from alerts.models import Alert
from predictions.models import PredictionLog


class AnalyticsDetailView(APIView):
    """
    GET /api/analytics/
    Real-world analytics derived from Region risk scores, PredictionLog history,
    and the Alert table.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        period = request.query_params.get('period', '7days')
        region_id = request.query_params.get('region_id')
        force = request.query_params.get('force', 'false').lower() == 'true'

        # Trigger dynamic region risk refresh so analytics have fresh live data!
        try:
            from api.views import _refresh_stale_region_risks
            _refresh_stale_region_risks(max_age_minutes=0 if force else 15)
        except Exception as e:
            print(f"[Analytics] Dynamic region risk refresh skipped: {e}")

        days = 1 if period == '24hours' else 30 if period == '30days' else 7
        local_now = timezone.localtime(timezone.now())
        start_dt = local_now - timezone.timedelta(days=days)

        # ── Region queryset ───────────────────────────────────────────────
        regions = Region.objects.all()
        if region_id:
            try:
                regions = regions.filter(id=int(region_id))
            except (ValueError, TypeError):
                pass

        region_ids = list(regions.values_list('id', flat=True))

        # ── Risk trend (daily) ────────────────────────────────────────────
        # Use PredictionLog if records exist for the period, otherwise
        # replicate the current risk score as a flat baseline.
        pred_qs = PredictionLog.objects.filter(
            region_id__in=region_ids,
            timestamp__gte=start_dt,
        )

        pred_map = {}
        if pred_qs.exists():
            # Group by day, average risk score
            daily_risk = (
                pred_qs
                .annotate(day=TruncDate('timestamp'))
                .values('day')
                .annotate(avg_risk=Avg('risk_score'))
            )
            for entry in daily_risk:
                if entry['day']:
                    pred_map[entry['day'].strftime('%Y-%m-%d')] = entry['avg_risk']

        avg_risk = (
            regions.aggregate(avg=Avg('current_risk_score'))['avg'] or 0
        )

        # ── Alerts per day (real Alert table) ────────────────────────────
        alert_qs = Alert.objects.filter(
            region_id__in=region_ids,
            timestamp__gte=start_dt,
        )

        daily_alerts = (
            alert_qs
            .annotate(day=TruncDate('timestamp'))
            .values('day')
            .annotate(count=Count('id'))
            .order_by('day')
        )

        # Build a day-keyed dict then align with labels
        alert_map = {
            entry['day'].strftime('%Y-%m-%d'): entry['count']
            for entry in daily_alerts
            if entry['day']
        }

        # Build unified lists of exactly matching sizes aligned to local dates
        risk_trend = []
        labels = []
        alerts_per_day = []

        for i in range(days):
            day = (local_now - timezone.timedelta(days=days - 1 - i)).date()
            key = day.strftime('%Y-%m-%d')
            
            # Generate local date labels
            labels.append(day.strftime('%a') if days <= 7 else str(day.day))
            
            # Map daily alerts
            alerts_per_day.append(alert_map.get(key, 0))
            
            # Map daily average risk trend
            if key in pred_map:
                risk_trend.append(round((pred_map[key] or 0) * 100, 1))
            else:
                risk_trend.append(round(avg_risk * 100, 1))

        # ── Risk breakdown (current live scores) ─────────────────────────
        critical_count = regions.filter(current_risk_score__gte=0.70).count()
        high_count     = regions.filter(current_risk_score__gte=0.50, current_risk_score__lt=0.70).count()
        medium_count   = regions.filter(current_risk_score__gte=0.30, current_risk_score__lt=0.50).count()
        low_count      = regions.filter(current_risk_score__lt=0.30).count()

        # ── Alert severity breakdown ──────────────────────────────────────
        severity_qs = (
            alert_qs
            .values('severity')
            .annotate(count=Count('id'))
        )
        severity_breakdown = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
        for entry in severity_qs:
            severity_breakdown[entry['severity']] = entry['count']

        # ── Per-region detail ─────────────────────────────────────────────
        regions_detail = []
        for region in regions.order_by('-current_risk_score'):
            score = region.current_risk_score or 0
            if score >= 0.70:
                level = 'CRITICAL'
            elif score >= 0.50:
                level = 'HIGH'
            elif score >= 0.30:
                level = 'MEDIUM'
            else:
                level = 'LOW'

            alert_count = Alert.objects.filter(
                region=region, timestamp__gte=start_dt
            ).count()

            regions_detail.append({
                'id': region.id,
                'name': region.name,
                'district': region.district,
                'risk_score': round(score * 100, 1),
                'risk_level': level,
                'alert_count': alert_count,
                'last_updated': timezone.localtime(region.last_updated).isoformat(),
            })

        return Response({
            'period': period,
            'period_days': days,
            'labels': labels,
            'risk_trend': risk_trend,
            'alerts_per_day': alerts_per_day,
            'critical_count': critical_count,
            'high_count': high_count,
            'medium_count': medium_count,
            'low_count': low_count,
            'total_regions': regions.count(),
            'total_alerts': alert_qs.count(),
            'alert_severity_breakdown': severity_breakdown,
            'regions_detail': regions_detail,
            # legacy keys kept for backward compat
            'high_risk_count': critical_count,
            'avg_rainfall': 0,
        }, status=status.HTTP_200_OK)
