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

from .models import IncidentReport, SafetyStatus
from .serializers import IncidentReportSerializer, SafetyStatusSerializer
from regions.models import Region


class SubmitReportView(APIView):
    """
    POST endpoint for submitting incident reports.
    
    POST /api/reports/submit/
    Body: { 'region_id': int, 'description': str, 'image': file (optional) }
    """
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    
    def post(self, request):
        region_id = request.data.get('region_id')
        description = request.data.get('description')
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
        
        # Create incident report
        incident_report = IncidentReport.objects.create(
            user=request.user,
            region=region,
            description=description,
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
            return Response(serializer.data, status=status.HTTP_200_OK)
        except SafetyStatus.DoesNotExist:
            return Response(
                {'is_safe': False, 'message': 'No safety status found for this user in this region'},
                status=status.HTTP_200_OK
            )

    def post(self, request):
        region_id = request.data.get('region_id')
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
        
        # Create or update safety status (unique constraint ensures one per user per region)
        safety_status, created = SafetyStatus.objects.update_or_create(
            user=request.user,
            region=region,
            defaults={'is_safe': True}
        )
        
        serializer = SafetyStatusSerializer(safety_status)
        
        action = 'marked' if created else 'updated'
        print(f"DEBUG: Safety status {action} for user {request.user.username}")
        
        return Response(
            {
                'status': 'success',
                'message': f'Safety status {action} successfully',
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
