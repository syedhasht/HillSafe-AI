"""
Reports API Views for incident reporting and safety status tracking.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, parsers
from rest_framework.authentication import TokenAuthentication
from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta

from .models import IncidentReport, SafetyStatus, SOSRequest
from .serializers import IncidentReportSerializer, SafetyStatusSerializer
from regions.models import Region


class SubmitReportView(APIView):
    """
    POST endpoint for submitting incident reports.
    
    POST /api/reports/submit/
    Body: {
      'region_id': int,
      'description': str,
      'latitude': float optional,
      'longitude': float optional,
      'area_name': str optional,
      'image': file optional
    }
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    
    def post(self, request):
        region_id = request.data.get('region_id')
        description = request.data.get('description')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        area_name = request.data.get('area_name') or ''
        image = request.FILES.get('image')
        
        # Validation
        if not region_id or not description:
            return Response(
                {
                    'error': 'region_id and description are required',
                    'received': {
                        'region_id': region_id,
                        'description': description
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            region = Region.objects.get(id=region_id)
        except Region.DoesNotExist:
            return Response(
                {'error': 'Region not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            latitude = float(latitude) if latitude not in (None, '') else None
            longitude = float(longitude) if longitude not in (None, '') else None
        except (ValueError, TypeError):
            return Response(
                {'error': 'latitude and longitude must be valid numbers when provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create incident report
        incident_report = IncidentReport.objects.create(
            user=request.user,
            region=region,
            description=description,
            latitude=latitude,
            longitude=longitude,
            area_name=str(area_name)[:255],
            image=image
        )
        
        serializer = IncidentReportSerializer(incident_report)
        
        return Response(
            {
                'status': 'success',
                'message': 'Incident report submitted successfully',
                'report': serializer.data
            },
            status=status.HTTP_201_CREATED
        )


class MarkSafeView(APIView):
    """
    POST endpoint for marking user as safe in a region.
    
    POST /api/reports/mark-safe/
    Body: { 'region_id': int }
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    cooldown = timedelta(minutes=30)
    
    def get(self, request):
        region_id = request.query_params.get('region_id')
        print(f"DEBUG: GET mark-safe - user: {request.user.username}, region: {region_id}")
        
        if not region_id:
            return Response(
                {'error': 'region_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            safety_status = SafetyStatus.objects.get(
                user=request.user,
                region_id=region_id
            )
            serializer = SafetyStatusSerializer(safety_status)
            data = serializer.data
            data['is_active'] = (
                safety_status.is_safe
                and timezone.now() < safety_status.last_marked_at + self.cooldown
            )
            return Response(data, status=status.HTTP_200_OK)
        except SafetyStatus.DoesNotExist:
            return Response(
                {
                    'is_safe': False,
                    'is_active': False,
                    'can_mark_again': True,
                    'seconds_until_next_mark': 0,
                    'message': 'No safety status found for this user in this region',
                },
                status=status.HTTP_200_OK
            )

    def post(self, request):
        region_id = request.data.get('region_id')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        area_name = request.data.get('area_name') or ''
        print(f"DEBUG: POST mark-safe - user: {request.user.username}, region: {region_id}")
        
        if not region_id:
            return Response(
                {'error': 'region_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            region = Region.objects.get(id=region_id)
        except Region.DoesNotExist:
            print(f"DEBUG: Region {region_id} not found")
            return Response(
                {'error': 'Region not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        existing_status = SafetyStatus.objects.filter(
            user=request.user,
            region=region,
        ).first()
        if existing_status:
            next_allowed_at = existing_status.last_marked_at + self.cooldown
            seconds_until_next_mark = max(0, int((next_allowed_at - timezone.now()).total_seconds()))
            if existing_status.is_safe and seconds_until_next_mark > 0:
                serializer = SafetyStatusSerializer(existing_status)
                return Response(
                    {
                        'status': 'cooldown',
                        'message': 'Safety status already recorded. You can mark yourself again after 30 minutes.',
                        'can_mark_again': False,
                        'seconds_until_next_mark': seconds_until_next_mark,
                        'next_allowed_at': next_allowed_at,
                        'safety_status': serializer.data,
                    },
                    status=status.HTTP_200_OK
                )

        try:
            latitude = float(latitude) if latitude is not None else None
            longitude = float(longitude) if longitude is not None else None
        except (ValueError, TypeError):
            return Response(
                {'error': 'latitude and longitude must be valid numbers when provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create or update safety status (unique constraint ensures one per user per region)
        safety_status, created = SafetyStatus.objects.update_or_create(
            user=request.user,
            region=region,
            defaults={
                'is_safe': True,
                'latitude': latitude,
                'longitude': longitude,
                'area_name': str(area_name)[:255],
            }
        )
        
        serializer = SafetyStatusSerializer(safety_status)
        
        action = 'marked' if created else 'updated'
        print(f"DEBUG: Safety status {action} for user {request.user.username}")
        
        return Response(
            {
                'status': 'success',
                'message': f'Safety status {action} successfully',
                'can_mark_again': False,
                'seconds_until_next_mark': int(self.cooldown.total_seconds()),
                'safety_status': serializer.data
            },
            status=status.HTTP_200_OK
        )


class RegionStatsView(APIView):
    """
    GET endpoint for region statistics (for authorities).
    
    GET /api/reports/stats/<region_id>/
    Returns safety counts and pending reports for a region
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request, region_id):
        try:
            region = Region.objects.get(id=region_id)
        except Region.DoesNotExist:
            return Response(
                {'error': 'Region not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Count users marked as safe in this region
        safe_count = SafetyStatus.objects.filter(
            region=region,
            is_safe=True
        ).count()
        
        # Count pending (unverified) incident reports
        pending_reports = IncidentReport.objects.filter(
            region=region,
            is_verified=False
        ).count()
        
        # Get most recent safety status update
        recent_status = SafetyStatus.objects.filter(
            region=region,
            is_safe=True
        ).order_by('-last_marked_at').first()
        
        if recent_status:
            time_diff = timezone.now() - recent_status.last_marked_at
            
            if time_diff.seconds < 60:
                last_check_in = 'Just now'
            elif time_diff.seconds < 3600:
                last_check_in = f'{time_diff.seconds // 60} mins ago'
            elif time_diff.seconds < 86400:
                last_check_in = f'{time_diff.seconds // 3600} hours ago'
            else:
                last_check_in = f'{time_diff.days} days ago'
        else:
            last_check_in = 'No recent check-ins'
        
        return Response(
            {
                'region_name': region.name,
                'safe_count': safe_count,
                'pending_reports': pending_reports,
                'last_check_in': last_check_in,
                'timestamp': timezone.now()
            },
            status=status.HTTP_200_OK
        )


class MyReportsView(APIView):
    """
    GET endpoint to fetch current user's incident reports.
    
    GET /api/reports/my-reports/
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        reports = IncidentReport.objects.filter(user=request.user)
        serializer = IncidentReportSerializer(reports, many=True)
        
        return Response(
            {
                'reports': serializer.data,
                'count': reports.count()
            },
            status=status.HTTP_200_OK
        )


class ReportListView(APIView):
    """
    GET endpoint to fetch ALL incident reports (for authorities).
    
    GET /api/reports/list/?region_id=1
    Returns all reports ordered by timestamp (newest first).
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        # Allow checking all reports or filtering by region
        region_id = request.query_params.get('region_id')
        
        reports = IncidentReport.objects.all().select_related('user', 'region').order_by('-timestamp')
        
        if region_id:
            try:
                reports = reports.filter(region_id=int(region_id))
            except ValueError:
                pass
        
        serializer = IncidentReportSerializer(reports, many=True)
        
        return Response(serializer.data, status=status.HTTP_200_OK)


class SubmitSOSView(APIView):
    """
    POST endpoint for emergency SOS requests.

    POST /api/reports/sos/
    Body: {
      latitude, longitude, region_id, area_name, risk_level,
      risk_score, message
    }
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        region_id = request.data.get('region_id')
        area_name = request.data.get('area_name') or ''
        risk_level = request.data.get('risk_level') or ''
        risk_score = request.data.get('risk_score')
        message = request.data.get('message') or 'Emergency SOS. User needs immediate help.'

        try:
            latitude = float(latitude)
            longitude = float(longitude)
        except (ValueError, TypeError):
            return Response(
                {'error': 'latitude and longitude are required and must be valid numbers'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        region = None
        if region_id:
            region = Region.objects.filter(id=region_id).first()

        if region is None:
            region = _find_nearest_region(latitude, longitude)

        try:
            risk_score = float(risk_score) if risk_score is not None else None
        except (ValueError, TypeError):
            risk_score = None

        sos = SOSRequest.objects.create(
            user=request.user,
            region=region,
            name=request.user.get_full_name() or request.user.username,
            phone_number=request.user.phone_number or '',
            latitude=latitude,
            longitude=longitude,
            area_name=str(area_name)[:255],
            risk_level=str(risk_level).upper()[:20],
            risk_score=risk_score,
            message=str(message),
        )

        return Response(
            {
                'status': 'success',
                'message': 'SOS request sent successfully',
                'sos': _serialize_sos(sos),
            },
            status=status.HTTP_201_CREATED,
        )


class SOSListView(APIView):
    """
    GET endpoint for authorities to view recent SOS requests.

    GET /api/reports/sos/list/
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        requests = SOSRequest.objects.select_related('user', 'region').order_by('-timestamp')[:25]
        return Response([_serialize_sos(sos) for sos in requests], status=status.HTTP_200_OK)


def _find_nearest_region(latitude, longitude):
    nearest = None
    nearest_distance = None

    for region in Region.objects.all():
        distance = _distance_km(latitude, longitude, region.latitude, region.longitude)
        if nearest_distance is None or distance < nearest_distance:
            nearest = region
            nearest_distance = distance

    return nearest


def _distance_km(lat1, lon1, lat2, lon2):
    import math

    radius = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _serialize_sos(sos):
    return {
        'id': sos.id,
        'user_id': sos.user_id,
        'name': sos.name,
        'phone_number': sos.phone_number,
        'latitude': sos.latitude,
        'longitude': sos.longitude,
        'area_name': sos.area_name,
        'region_id': sos.region_id,
        'region_name': sos.region.name if sos.region else sos.area_name or 'Unknown',
        'risk_level': sos.risk_level,
        'risk_score': sos.risk_score,
        'message': sos.message,
        'status': sos.status,
        'status_label': sos.get_status_display(),
        'timestamp': sos.timestamp,
    }
