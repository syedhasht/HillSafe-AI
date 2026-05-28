import random
from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.utils import timezone
from accounts.models import User
from regions.models import Region
from alerts.models import Alert
from ml_engine.risk_pipeline import predict_region_risk
from .serializers import UserSerializer, RegionSerializer, AlertSerializer


class CustomLoginView(APIView):
    """
    Passwordless login endpoint for HillSafe AI.
    
    Authenticates users with username and phone number only.
    No password required for community users.
    
    POST /api/login/
    Request body: { "username": "johndoe", "phone_number": "+1234567890" }
    Response: { "token": "<token>", "role": "COMMUNITY", "username": "johndoe", "user_id": 1 }
    """
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        username = request.data.get('username')
        phone_number = request.data.get('phone_number')
        
        if not username or not phone_number:
            return Response(
                {'error': 'Please provide both username and phone number'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Find user by username and phone number (passwordless auth)
        try:
            user = User.objects.get(username=username, phone_number=phone_number)
            
            # Get or create token for the user
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'token': token.key,
                'role': user.role,
                'username': user.username,
                'user_id': user.id,
                'phone_number': user.phone_number,
                'email': user.email or ''
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Invalid credentials. Username or phone number not found.'},
                status=status.HTTP_401_UNAUTHORIZED
            )



class RegionListView(generics.ListAPIView):
    """
    List all regions.
    
    GET /api/regions/
    Returns all Region objects with location data and risk scores.
    """
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        refresh = self.request.query_params.get('refresh', 'true').lower() != 'false'
        if refresh:
            refresh_stale_region_risks()
        return Region.objects.all()


def refresh_stale_region_risks(max_age_minutes=15, max_regions=3):
    cutoff = timezone.now() - timezone.timedelta(minutes=max_age_minutes)
    stale_regions = list(
        Region.objects.filter(last_updated__lt=cutoff).order_by('last_updated')[:max_regions]
    )

    for region in stale_regions:
        try:
            prediction = predict_region_risk(region)
        except Exception as exc:
            print(f"Region risk refresh failed for {region.name}: {exc}")
            continue

        region.current_risk_score = prediction['risk_score']
        region.save(update_fields=['current_risk_score', 'updated_at', 'last_updated'])


class AlertListView(generics.ListAPIView):
    """
    List all active alerts.
    
    GET /api/alerts/
    Returns active alerts ordered by timestamp (newest first).
    """
    serializer_class = AlertSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_queryset(self):
        # Return all alerts for history, ordered by newest first
        return Alert.objects.all().order_by('-timestamp')


class AnalyticsView(APIView):
    """
    Analytics data endpoint.
    
    GET /api/analytics/?period=7days&region_id=1
    
    Query Parameters:
    - period: '24hours', '7days', or '30days' (default: '7days')
    - region_id: Optional region ID to filter analytics
    
    Returns:
    - rainfall_trend: List of rainfall values over the period
    - risk_trend: List of risk scores over the period
    - high_risk_count: Number of high-risk regions
    - avg_rainfall: Average rainfall across the period
    - total_regions: Total number of regions analyzed
    - period_days: Number of days in the period
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        period = request.query_params.get('period', '7days')
        region_id = request.query_params.get('region_id', None)
        
        # Determine number of days based on period
        if period == '24hours':
            days = 1
        elif period == '7days':
            days = 7
        elif period == '30days':
            days = 30
        else:
            days = 7
        
        # Query regions
        regions = Region.objects.all()
        if region_id:
            try:
                regions = regions.filter(id=int(region_id))
            except (ValueError, TypeError):
                pass
        
        # Generate analytics data
        if regions.exists():
            # Calculate average risk score across all regions
            total_risk = sum(r.current_risk_score for r in regions)
            avg_risk = total_risk / regions.count()
            
            # Generate trend data (simulated based on current risk)
            # In production, this would query historical data
            rainfall_trend = []
            risk_trend = []
            
            for i in range(days):
                # Simulate variation in data with random noise for realism
                noise = random.uniform(0.85, 1.15)  # +/- 15% fluctuation
                
                daily_risk = avg_risk * 100 * noise
                daily_risk = min(100, max(5, daily_risk))
                
                rainfall_noise = random.uniform(0.7, 1.3)
                daily_rainfall = (daily_risk * 0.4) * rainfall_noise 
                
                rainfall_trend.append(round(daily_rainfall, 1))
                risk_trend.append(round(daily_risk, 1))
            
            # Count high-risk regions (score >= 0.7)
            high_risk_count = regions.filter(current_risk_score__gte=0.7).count()
            
            # Calculate average rainfall
            avg_rainfall = sum(rainfall_trend) / len(rainfall_trend) if rainfall_trend else 0
            
            analytics_data = {
                'rainfall_trend': rainfall_trend,
                'risk_trend': risk_trend,
                'high_risk_count': high_risk_count,
                'avg_rainfall': round(avg_rainfall, 1),
                'total_regions': regions.count(),
                'period_days': days,
            }
        else:
            # No regions found
            analytics_data = {
                'rainfall_trend': [0] * days,
                'risk_trend': [0] * days,
                'high_risk_count': 0,
                'avg_rainfall': 0,
                'total_regions': 0,
                'period_days': days,
            }
        
        return Response(analytics_data, status=status.HTTP_200_OK)


class SensorDataView(APIView):
    """
    GET /api/sensor-data/
    Returns aggregated sensor data from all regions.
    Used by War Room to display live sensor metrics.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        regions = Region.objects.all()
        
        if not regions.exists():
            return Response({
                'rainfall': '0mm',
                'soil_moisture': '0%',
                'avg_risk': '0%',
                'high_risk_count': 0,
                'region_count': 0,
            })
        
        # Aggregate sensor data
        total_rainfall = 0
        total_soil_moisture = 0
        total_risk = 0
        high_risk_count = 0
        
        for region in regions:
            # Get risk score
            risk_score = region.current_risk_score or 0
            total_risk += risk_score
            if risk_score >= 0.7:
                high_risk_count += 1
            
            # Simulate sensor data based on risk (in production, use actual sensors)
            # Higher risk = more rainfall and soil moisture
            total_rainfall += int(risk_score * 15)  # 0-15mm per region
            total_soil_moisture += int(60 + risk_score * 30)  # 60-90%
        
        count = regions.count()
        
        return Response({
            'rainfall': f"{int(total_rainfall / count)}mm",
            'soil_moisture': f"{int(total_soil_moisture / count)}%",
            'avg_risk': f"{int(total_risk / count * 100)}%",
            'high_risk_count': high_risk_count,
            'region_count': count,
        })


class DistrictsView(APIView):
    """
    GET /api/districts/
    Returns list of unique districts from regions.
    Used for dynamic district dropdowns throughout the app.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        # Get unique districts, excluding None/empty values
        districts = Region.objects.exclude(
            district__isnull=True
        ).exclude(
            district=''
        ).values_list('district', flat=True).distinct().order_by('district')
        
        return Response({
            'districts': list(districts)
        })


class SafetyStatusView(APIView):
    """
    GET /api/safety-status/
    Returns count of users who marked themselves safe, grouped by region.
    Used by Command Center to display safety statistics.
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request):
        from accounts.models import User
        from reports.models import SafetyStatus
        
        regions = Region.objects.all()
        safety_data = []
        active_cutoff = timezone.now() - timezone.timedelta(minutes=30)
        
        for region in regions:
            safe_checkins = SafetyStatus.objects.filter(
                region=region,
                is_safe=True,
                last_marked_at__gte=active_cutoff,
            )
            safe_count = safe_checkins.count()
            total_users = User.objects.filter(role='COMMUNITY').count()
            latest_checkin = safe_checkins.select_related('user').order_by('-last_marked_at').first()

            latest_data = None
            if latest_checkin:
                latest_data = {
                    'user_name': latest_checkin.user.username,
                    'area_name': latest_checkin.area_name,
                    'latitude': latest_checkin.latitude,
                    'longitude': latest_checkin.longitude,
                    'last_marked_at': latest_checkin.last_marked_at,
                }

            safety_data.append({
                'region_id': region.id,
                'region_name': region.name,
                'district': region.district,
                'safe_count': safe_count,
                'total_users': total_users,
                'percentage': round((safe_count / total_users * 100) if total_users > 0 else 0, 1),
                'latest_checkin': latest_data,
            })

        active_safe = SafetyStatus.objects.filter(
            is_safe=True,
            last_marked_at__gte=active_cutoff,
        )
        recent_checkins = []
        for checkin in active_safe.select_related('user', 'region').order_by('-last_marked_at')[:10]:
            recent_checkins.append({
                'id': checkin.id,
                'user_name': checkin.user.username,
                'region_id': checkin.region.id,
                'region_name': checkin.region.name,
                'district': checkin.region.district,
                'area_name': checkin.area_name,
                'latitude': checkin.latitude,
                'longitude': checkin.longitude,
                'last_marked_at': checkin.last_marked_at,
            })
        
        # Overall stats
        total_safe = active_safe.count()
        total_users_all = User.objects.filter(role='COMMUNITY').count()
        
        return Response({
            'regions': safety_data,
            'total_safe': total_safe,
            'total_users': total_users_all,
            'overall_percentage': round((total_safe / total_users_all * 100) if total_users_all > 0 else 0, 1),
            'recent_checkins': recent_checkins,
            'active_window_minutes': 30,
        })


class MarkSafeView(APIView):
    """
    POST /api/mark-safe/
    Allows users to mark themselves as safe or unsafe.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        from accounts.models import User
        from django.utils import timezone
        
        user_id = request.data.get('user_id')
        region_id = request.data.get('region_id')
        is_safe = request.data.get('is_safe', True)
        
        if not user_id:
            return Response({
                'success': False,
                'error': 'user_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(id=user_id)
            user.is_safe = is_safe
            user.safe_status_updated_at = timezone.now()
            
            if region_id:
                try:
                    user.location_region_id = int(region_id)
                except (ValueError, TypeError):
                    pass
            
            user.save()
            
            return Response({
                'success': True,
                'message': f'Safety status updated to {"safe" if is_safe else "unsafe"}',
                'is_safe': user.is_safe,
                'updated_at': user.safe_status_updated_at
            })
        except User.DoesNotExist:
            return Response({
                'success': False,
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
