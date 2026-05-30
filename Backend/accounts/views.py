"""
API views for user accounts and device token management.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import AuthorityProfile, DeviceToken, ResidentProfile


def sync_role_profile(user):
    profile_model = AuthorityProfile if user.role == 'AUTHORITY' else ResidentProfile
    profile, _ = profile_model.objects.get_or_create(
        user=user,
        defaults={
            'username': user.username,
            'phone_number': user.phone_number,
            'email': user.email or '',
        },
    )
    fields = []
    if profile.username != user.username:
        profile.username = user.username
        fields.append('username')
    if profile.phone_number != user.phone_number:
        profile.phone_number = user.phone_number
        fields.append('phone_number')
    if profile.email != (user.email or ''):
        profile.email = user.email or ''
        fields.append('email')
    if fields:
        fields.append('updated_at')
        profile.save(update_fields=fields)
    return profile


class ProfileView(APIView):
    """
    GET/PATCH current user's profile.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        role_profile = sync_role_profile(user)
        return Response(
            {
                'username': user.username,
                'phone_number': user.phone_number,
                'email': user.email or '',
                'profile_email': role_profile.email,
                'language': user.language,
                'role': user.role,
                'user_id': user.id,
                'user_key': user.phone_number,
                'profile_table': 'authority_profile' if user.role == 'AUTHORITY' else 'resident_profile',
                'dark_mode': user.dark_mode,
            },
            status=status.HTTP_200_OK,
        )

    def patch(self, request):
        user = request.user
        username = (request.data.get('username') or '').strip()
        email = (request.data.get('email') or '').strip()
        phone_number = (request.data.get('phone_number') or '').strip()
        language = (request.data.get('language') or '').strip()
        dark_mode = request.data.get('dark_mode')

        if username:
            user.username = username

        user.email = email
        update_fields = ['username', 'email']

        if phone_number and phone_number != user.phone_number:
            from .models import User
            if User.objects.filter(phone_number=phone_number).exclude(id=user.id).exists():
                return Response(
                    {'error': 'Phone number already registered by another account.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.phone_number = phone_number
            update_fields.append('phone_number')

        if language in dict(user.LANGUAGE_CHOICES):
            user.language = language
            update_fields.append('language')

        if dark_mode is not None:
            user.dark_mode = bool(dark_mode)
            update_fields.append('dark_mode')

        user.save(update_fields=update_fields)
        role_profile = sync_role_profile(user)

        return Response(
            {
                'username': user.username,
                'phone_number': user.phone_number,
                'email': user.email or '',
                'profile_email': role_profile.email,
                'language': user.language,
                'role': user.role,
                'user_id': user.id,
                'user_key': user.phone_number,
                'profile_table': 'authority_profile' if user.role == 'AUTHORITY' else 'resident_profile',
                'dark_mode': user.dark_mode,
            },
            status=status.HTTP_200_OK,
        )


class SaveDeviceTokenView(APIView):
    """
    POST endpoint for saving Firebase Cloud Messaging device tokens.
    
    POST /api/save-device-token/
    Body: {
      'token': 'firebase_device_token_here',
      'latitude': 34.123,   optional but needed for radius alerts
      'longitude': 73.456   optional but needed for radius alerts
    }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        token = request.data.get('token')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        if not token:
            return Response(
                {'error': 'token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            latitude = float(latitude) if latitude is not None else None
            longitude = float(longitude) if longitude is not None else None
        except (TypeError, ValueError):
            return Response(
                {'error': 'latitude and longitude must be valid numbers when provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        defaults = {'user': request.user}
        if latitude is not None and longitude is not None:
            defaults.update({
                'latitude': latitude,
                'longitude': longitude,
                'location_updated_at': timezone.now(),
            })
        
        # Update or create device token for this user
        device_token, created = DeviceToken.objects.update_or_create(
            token=token,
            defaults=defaults
        )
        
        action = 'registered' if created else 'updated'
        
        return Response(
            {
                'status': 'success',
                'message': f'Device token {action} successfully',
                'token_id': device_token.id,
                'latitude': device_token.latitude,
                'longitude': device_token.longitude,
            },
            status=status.HTTP_200_OK
        )
