"""
API views for user accounts and device token management.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import DeviceToken


class SaveDeviceTokenView(APIView):
    """
    POST endpoint for saving Firebase Cloud Messaging device tokens.
    
    POST /api/save-device-token/
    Body: { 'token': 'firebase_device_token_here' }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        token = request.data.get('token')
        
        if not token:
            return Response(
                {'error': 'token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update or create device token for this user
        device_token, created = DeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': request.user}
        )
        
        action = 'registered' if created else 'updated'
        
        return Response(
            {
                'status': 'success',
                'message': f'Device token {action} successfully',
                'token_id': device_token.id
            },
            status=status.HTTP_200_OK
        )
