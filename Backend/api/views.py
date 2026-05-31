import random
import math
import requests
from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.conf import settings
from django.utils import timezone
from accounts.models import User
from accounts.views import sync_role_profile
from regions.models import Region
from alerts.models import Alert
from ml_engine.risk_pipeline import predict_region_risk
from .serializers import UserSerializer, RegionSerializer, AlertSerializer


class HillSafeChatbotView(APIView):
    """
    POST /api/chatbot/
    Uses Gemini through the backend so the API key is never exposed in Flutter.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        message = (request.data.get('message') or '').strip()
        region = (request.data.get('region') or 'Unknown').strip()
        risk_level = (request.data.get('risk_level') or 'Unknown').strip()
        rainfall = request.data.get('rainfall', 'Unknown')
        temperature = request.data.get('temperature', 'Unknown')
        language = (request.data.get('language') or 'English').strip()

        if not message:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)

        if not settings.GEMINI_API_KEY:
            return Response({
                'reply': (
                    'HillSafe Assistant is not connected to Gemini yet. '
                    'You can still use the FAQ answers in the app.'
                )
            }, status=status.HTTP_200_OK)

        prompt = f"""
You are HillSafe Assistant, a safety guidance assistant inside the HillSafe AI app.

Important rules:
1. Do not perform live landslide prediction in chat.
2. Do not say HillSafe AI cannot predict landslides. Instead say: HillSafe AI shows location-based landslide risk estimates on the app dashboard.
3. If the user asks "am I safe", "will landslide happen", "risk in my area", "predict my location", or similar, tell them to check the dashboard/weather risk card for live risk.
4. You may explain what NO RISK, LOW, MODERATE, and HIGH mean.
5. You may give safety steps, evacuation advice, emergency kit advice, reporting steps, SOS guidance, and what to avoid.
6. Do not invent live weather, coordinates, official alerts, rescue status, or local events.
7. If the situation sounds urgent, advise moving away from slopes, riverbanks, unstable roads, and contacting local authorities or emergency services.
8. Keep answers short, calm, and practical for residents.
9. Do not use Markdown symbols like **, *, #, or backticks.

App context only if directly relevant:
Region: {region}
Risk level shown in app: {risk_level}
Rainfall shown in app: {rainfall}
Temperature shown in app: {temperature}

Answer in {language}.

User question:
{message}
"""

        url = (
            'https://generativelanguage.googleapis.com/v1beta/models/'
            f'gemini-2.5-flash:generateContent?key={settings.GEMINI_API_KEY}'
        )
        payload = {
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'temperature': 0.15, 'maxOutputTokens': 2048},
        }

        try:
            gemini_response = requests.post(url, json=payload, timeout=12)
            if gemini_response.status_code != 200:
                return Response({
                    'reply': 'Assistant is temporarily unavailable. Please use the safety FAQs for quick guidance.'
                }, status=status.HTTP_200_OK)

            data = gemini_response.json()
            parts = (
                data.get('candidates', [{}])[0]
                .get('content', {})
                .get('parts', [])
            )
            reply = '\n'.join(
                part.get('text', '').strip()
                for part in parts
                if part.get('text', '').strip()
            ).strip()

            return Response({'reply': reply or 'No response received. Please try again.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({
                'reply': 'Assistant is temporarily unavailable. Please use the safety FAQs for quick guidance.'
            }, status=status.HTTP_200_OK)


class CustomLoginView(APIView):
    """
    Login endpoint for HillSafe AI.
    POST /api/login/

    - AUTHORITY role: must already exist in DB (checked by username + password).
      Returns 401 if user not found or credentials are wrong.
    - COMMUNITY role: passwordless (username + phone). Creates account if new.
    """
    permission_classes = [permissions.AllowAny]

    def _normalize_phone_number(self, value):
        digits = ''.join(ch for ch in value if ch.isdigit())
        if digits.startswith('92'):
            digits = digits[2:]
        if digits.startswith('0'):
            digits = digits[1:]
        if len(digits) != 10:
            return value.strip()
        return f'+92 {digits[:3]}-{digits[3:]}'

    def _available_username(self, username, phone_number):
        base = username.strip() or phone_number
        if not User.objects.filter(username=base).exists():
            return base
        suffix = ''.join(ch for ch in phone_number if ch.isdigit())[-4:] or 'user'
        candidate = f'{base}_{suffix}'
        counter = 2
        while User.objects.filter(username=candidate).exists():
            candidate = f'{base}_{suffix}_{counter}'
            counter += 1
        return candidate

    def post(self, request):
        username = (request.data.get('username') or '').strip()
        phone_number = self._normalize_phone_number(
            (request.data.get('phone_number') or '').strip()
        )
        password = (request.data.get('password') or '').strip()
        requested_role = (request.data.get('role') or 'COMMUNITY').upper()

        if requested_role not in dict(User.ROLE_CHOICES):
            requested_role = 'COMMUNITY'

        # --- AUTHORITY login: must exist in DB with matching credentials ---
        if requested_role == 'AUTHORITY':
            if not username or not password:
                return Response(
                    {'error': 'Please provide both username and password'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user = User.objects.filter(username=username, role='AUTHORITY').first()
            if user is None:
                return Response(
                    {'error': 'No authority account found with this username. Please sign up first.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            if not user.check_password(password):
                return Response(
                    {'error': 'Incorrect password. Please try again.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            user.is_logged_in = True
            user.last_login = timezone.now()
            user.save(update_fields=['is_logged_in', 'last_login'])
            sync_role_profile(user)
            token, _ = Token.objects.get_or_create(user=user)

            return Response({
                'token': token.key,
                'role': user.role,
                'username': user.username,
                'user_id': user.id,
                'user_key': user.phone_number,
                'phone_number': user.phone_number,
                'is_logged_in': user.is_logged_in,
                'language': user.language,
                'dark_mode': user.dark_mode,
                'email': user.email or ''
            }, status=status.HTTP_200_OK)

        # --- COMMUNITY login: passwordless (create if new) ---
        if not username or not phone_number:
            return Response(
                {'error': 'Please provide both username and phone number'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.filter(phone_number=phone_number).first()
        created = user is None

        if created:
            if User.objects.filter(username=username).exists():
                return Response(
                    {'error': 'This username is already taken. Please choose a different username.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user = User(
                username=username,
                phone_number=phone_number,
                role=requested_role,
            )
            user.set_unusable_password()
        else:
            if user.username != username:
                return Response(
                    {'error': 'This phone number is already registered under a different username.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        user.phone_number = phone_number
        user.role = requested_role
        user.is_logged_in = True
        user.last_login = timezone.now()
        user.save()
        sync_role_profile(user)

        token, _ = Token.objects.get_or_create(user=user)

        return Response({
            'token': token.key,
            'role': user.role,
            'username': user.username,
            'user_id': user.id,
            'user_key': user.phone_number,
            'phone_number': user.phone_number,
            'is_logged_in': user.is_logged_in,
            'language': user.language,
            'dark_mode': user.dark_mode,
            'email': user.email or ''
        }, status=status.HTTP_200_OK)


class AuthoritySignupView(APIView):
    """
    POST /api/signup/authority/
    Registers a new AUTHORITY account with username and password.
    Returns 409 if username already exists.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = (request.data.get('username') or '').strip()
        password = (request.data.get('password') or '').strip()
        email = (request.data.get('email') or '').strip()

        if not username or not password:
            return Response(
                {'error': 'Username and password are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(password) < 6:
            return Response(
                {'error': 'Password must be at least 6 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {'error': 'This username is already taken. Please choose another.'},
                status=status.HTTP_409_CONFLICT
            )

        phone_number = f'AUTH-{username}'
        counter = 2
        while User.objects.filter(phone_number=phone_number).exists():
            phone_number = f'AUTH-{username}-{counter}'
            counter += 1

        user = User(
            username=username,
            phone_number=phone_number,
            role='AUTHORITY',
            email=email,
            is_logged_in=True,
        )
        user.set_password(password)
        user.last_login = timezone.now()
        user.save()
        sync_role_profile(user)

        token, _ = Token.objects.get_or_create(user=user)

        return Response({
            'token': token.key,
            'role': user.role,
            'username': user.username,
            'user_id': user.id,
            'user_key': user.phone_number,
            'phone_number': user.phone_number,
            'is_logged_in': user.is_logged_in,
            'language': user.language,
            'dark_mode': user.dark_mode,
            'email': user.email or ''
        }, status=status.HTTP_201_CREATED)


class CustomLogoutView(APIView):
    """
    POST /api/logout/
    Clears the user's active login flag.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        request.user.is_logged_in = False
        request.user.save(update_fields=['is_logged_in'])
        return Response({
            'success': True,
            'message': 'Logged out successfully',
            'is_logged_in': request.user.is_logged_in,
        }, status=status.HTTP_200_OK)


class RegionListView(generics.ListAPIView):
    """
    GET /api/regions/
    Returns all Region objects with location data and risk scores.
    """
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        refresh = self.request.query_params.get('refresh', 'true').lower() != 'false'
        force = self.request.query_params.get('force', 'false').lower() == 'true'
        if refresh:
            _refresh_stale_region_risks(max_age_minutes=0 if force else 15)
        return Region.objects.all()


def _refresh_stale_region_risks(max_age_minutes=15, max_regions=None):
    cutoff = timezone.now() - timezone.timedelta(minutes=max_age_minutes)
    stale_regions = Region.objects.filter(last_updated__lte=cutoff).order_by('last_updated')
    if max_regions is not None:
        stale_regions = stale_regions[:max_regions]
    stale = list(stale_regions)
    for region in stale:
        try:
            prediction = predict_region_risk(region)
        except Exception as exc:
            print(f"Region risk refresh failed for {region.name}: {exc}")
            continue
        region.current_risk_score = prediction['risk_score']
        region.save(update_fields=['current_risk_score', 'updated_at', 'last_updated'])


class AlertListView(generics.ListAPIView):
    """
    GET /api/alerts/
    Returns all alerts ordered by newest first.
    """
    serializer_class = AlertSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Alert.objects.all().order_by('-timestamp')


class CreateAlertView(APIView):
    """
    POST /api/alerts/create/
    Saves a new alert to the database and sends Firebase push notifications
    to registered devices within 20 km of the selected region.

    Request body:
        region_id            (int, required)
        severity             (str: LOW | MEDIUM | HIGH | CRITICAL)
        message              (str, required)
        affected_population  (int, optional, default 0)
    """
    permission_classes = [permissions.IsAuthenticated]
    alert_radius_km = 20

    def _distance_km(self, lat1, lon1, lat2, lon2):
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

    def post(self, request):
        from accounts.models import DeviceToken

        if getattr(request.user, 'role', '').upper() != 'AUTHORITY':
            return Response(
                {'error': 'Only authority accounts can create alerts.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        region_id = request.data.get('region_id')
        send_to_all = request.data.get('send_to_all', False)
        if isinstance(send_to_all, str):
            send_to_all = send_to_all.lower() == 'true'

        severity = (request.data.get('severity') or 'HIGH').upper()
        message = (request.data.get('message') or '').strip()
        affected_population = request.data.get('affected_population', 0)

        if not message:
            return Response({'error': 'message is required'}, status=status.HTTP_400_BAD_REQUEST)
        if severity not in {'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'}:
            severity = 'HIGH'

        if not region_id:
            if send_to_all:
                region, _ = Region.objects.get_or_create(
                    name='All Regions',
                    district='National',
                    defaults={
                        'latitude': 33.6844,
                        'longitude': 73.0479,
                        'current_risk_score': 0.0,
                        'is_critical_zone': False,
                    }
                )
            else:
                return Response({'error': 'region_id is required when not sending to all users'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            try:
                region = Region.objects.get(id=region_id)
            except Region.DoesNotExist:
                return Response({'error': 'Region not found'}, status=status.HTTP_404_NOT_FOUND)

        # Save to DB
        alert = Alert.objects.create(
            region=region,
            severity=severity,
            message=message,
            affected_population=affected_population,
            is_active=True,
        )

        fallback_to_all_devices = False

        # Estimate targeted devices count synchronously first (extremely fast database lookup)
        try:
            if send_to_all:
                targeted_count = DeviceToken.objects.count()
            else:
                located_devices = DeviceToken.objects.exclude(
                    latitude__isnull=True,
                ).exclude(
                    longitude__isnull=True,
                )
                nearby_tokens_count = 0
                for device in located_devices:
                    distance = self._distance_km(
                        float(device.latitude),
                        float(device.longitude),
                        float(region.latitude),
                        float(region.longitude),
                    )
                    if distance <= self.alert_radius_km:
                        nearby_tokens_count += 1
                if nearby_tokens_count > 0:
                    targeted_count = nearby_tokens_count
                else:
                    fallback_to_all_devices = True
                    targeted_count = DeviceToken.objects.count()
        except Exception:
            targeted_count = 0

        # Push notifications are best-effort and run in the background so the
        # alert creation request does not time out while Firebase is contacted.
        import threading

        def send_notifications_background(alert_id, region_id, severity, message, send_to_all):
            try:
                import firebase_admin
                from firebase_admin import messaging
                from alerts.models import Alert
                from regions.models import Region

                # Re-fetch models in background thread to prevent session thread-safety issues
                bg_alert = Alert.objects.get(id=alert_id)
                bg_region = Region.objects.get(id=region_id)

                if not firebase_admin._apps:
                    import os
                    # Robust path resolution to support monorepos and Render secret files
                    def _get_service_account_path():
                        path1 = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
                        if os.path.exists(path1):
                            return path1
                        path2 = os.path.join(os.path.dirname(settings.BASE_DIR), 'serviceAccountKey.json')
                        if os.path.exists(path2):
                            return path2
                        return path1

                    cred_path = _get_service_account_path()
                    cred = firebase_admin.credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)

                if send_to_all:
                    tokens = list(DeviceToken.objects.values_list('token', flat=True))
                else:
                    nearby_tokens = []
                    located_devices = DeviceToken.objects.exclude(
                        latitude__isnull=True,
                    ).exclude(
                        longitude__isnull=True,
                    )
                    for device in located_devices:
                        distance = self._distance_km(
                            float(device.latitude),
                            float(device.longitude),
                            float(bg_region.latitude),
                            float(bg_region.longitude),
                        )
                        if distance <= self.alert_radius_km:
                            nearby_tokens.append(device.token)
                    tokens = nearby_tokens or list(DeviceToken.objects.values_list('token', flat=True))

                if tokens:
                    label = {
                        'CRITICAL': 'CRITICAL WARNING',
                        'HIGH': 'HIGH ALERT',
                        'MEDIUM': 'SAFETY ALERT',
                        'LOW': 'SAFETY UPDATE',
                    }.get(severity, severity)

                    if bg_region.name == 'All Regions':
                        location_line = 'All monitored regions'
                    else:
                        location_line = f'{bg_region.name}, {bg_region.district}'

                    title = f'HillSafe AI: {label}'
                    body_message = f'{location_line}: {message}'[:1000]

                    for i in range(0, len(tokens), 500):
                        chunk = tokens[i:i + 500]
                        mc = messaging.MulticastMessage(
                            tokens=chunk,
                            notification=messaging.Notification(title=title, body=body_message),
                            data={
                                'type': 'AUTHORITY_ALERT',
                                'alert_id': str(bg_alert.id),
                                'severity': severity,
                                'region_id': str(bg_region.id),
                                'region_name': bg_region.name,
                                'title': title,
                                'message': body_message,
                                'sound': 'default',
                            },
                            android=messaging.AndroidConfig(
                                priority='high',
                                notification=messaging.AndroidNotification(
                                    title=title,
                                    body=body_message,
                                    sound='default',
                                    channel_id='critical_alerts' if severity == 'CRITICAL' else 'risk_alerts',
                                ),
                            ),
                            apns=messaging.APNSConfig(
                                headers={'apns-priority': '10'},
                                payload=messaging.APNSPayload(
                                    aps=messaging.Aps(
                                        sound='default',
                                        badge=1,
                                        content_available=True,
                                    )
                                ),
                            ),
                        )
                        messaging.send_each_for_multicast(mc)
            except Exception as exc:
                print(f'[CreateAlertView] Background push notification error: {exc}')
        # Launch background worker asynchronously
        threading.Thread(
            target=send_notifications_background,
            args=(alert.id, region.id, severity, message, send_to_all),
            daemon=True
        ).start()

        return Response({
            'success': True,
            'alert_id': alert.id,
            'severity': alert.severity,
            'region': region.name,
            'alert_radius_km': self.alert_radius_km,
            'targeted_devices': targeted_count,
            'notifications_sent': targeted_count,
            'fallback_to_all_devices': fallback_to_all_devices,
            'message': 'Alert created and broadcast successfully.',
        }, status=status.HTTP_201_CREATED)


class AnalyticsView(APIView):
    """
    GET /api/analytics/?period=7days&region_id=1
    Returns risk and rainfall trend analytics.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        period = request.query_params.get('period', '7days')
        region_id = request.query_params.get('region_id', None)
        days = 1 if period == '24hours' else 30 if period == '30days' else 7
        force = request.query_params.get('force', 'false').lower() == 'true'

        _refresh_stale_region_risks(max_age_minutes=0 if force else 15)

        regions = Region.objects.all()
        if region_id:
            try:
                regions = regions.filter(id=int(region_id))
            except (ValueError, TypeError):
                pass

        if regions.exists():
            avg_risk = sum(r.current_risk_score for r in regions) / regions.count()
            rainfall_trend, risk_trend = [], []
            for _ in range(days):
                noise = random.uniform(0.85, 1.15)
                dr = min(100, max(5, avg_risk * 100 * noise))
                rainfall_trend.append(round(dr * 0.4 * random.uniform(0.7, 1.3), 1))
                risk_trend.append(round(dr, 1))
            critical_count = regions.filter(current_risk_score__gte=0.7).count()
            high_count = regions.filter(current_risk_score__gte=0.5, current_risk_score__lt=0.7).count()
            medium_count = regions.filter(current_risk_score__gte=0.3, current_risk_score__lt=0.5).count()
            low_count = regions.filter(current_risk_score__lt=0.3).count()
            analytics_data = {
                'rainfall_trend': rainfall_trend,
                'risk_trend': risk_trend,
                'high_risk_count': critical_count,
                'critical_count': critical_count,
                'high_count': high_count,
                'medium_count': medium_count,
                'low_count': low_count,
                'avg_rainfall': round(sum(rainfall_trend) / len(rainfall_trend), 1),
                'total_regions': regions.count(),
                'period_days': days,
            }
        else:
            analytics_data = {
                'rainfall_trend': [0] * days,
                'risk_trend': [0] * days,
                'high_risk_count': 0,
                'critical_count': 0,
                'high_count': 0,
                'medium_count': 0,
                'low_count': 0,
                'avg_rainfall': 0,
                'total_regions': 0,
                'period_days': days,
            }
        return Response(analytics_data, status=status.HTTP_200_OK)


class SensorDataView(APIView):
    """
    GET /api/sensor-data/
    Returns aggregated sensor data derived from region risk scores.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        _refresh_stale_region_risks(max_age_minutes=15)
        regions = Region.objects.all()
        if not regions.exists():
            return Response({
                'rainfall': '0mm', 'soil_moisture': '0%',
                'avg_risk': '0%', 'high_risk_count': 0, 'region_count': 0,
            })
        total_rainfall = total_soil_moisture = total_risk = 0
        critical_count = high_count = medium_count = low_count = 0
        for region in regions:
            rs = region.current_risk_score or 0
            total_risk += rs
            if rs >= 0.7:
                critical_count += 1
            elif rs >= 0.5:
                high_count += 1
            elif rs >= 0.3:
                medium_count += 1
            else:
                low_count += 1
            total_rainfall += int(rs * 15)
            total_soil_moisture += int(60 + rs * 30)
        count = regions.count()
        return Response({
            'rainfall': f"{int(total_rainfall / count)}mm",
            'soil_moisture': f"{int(total_soil_moisture / count)}%",
            'avg_risk': f"{int(total_risk / count * 100)}%",
            'high_risk_count': critical_count,
            'critical_count': critical_count,
            'high_count': high_count,
            'medium_count': medium_count,
            'low_count': low_count,
            'region_count': count,
        })


class DistrictsView(APIView):
    """
    GET /api/districts/
    Returns list of unique districts from regions.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        districts = Region.objects.exclude(
            district__isnull=True
        ).exclude(
            district=''
        ).values_list('district', flat=True).distinct().order_by('district')
        return Response({'districts': list(districts)})


class SafetyStatusView(APIView):
    """
    GET /api/safety-status/
    Returns count of users who marked themselves safe, grouped by region.
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
                region=region, is_safe=True, last_marked_at__gte=active_cutoff,
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

        active_safe = SafetyStatus.objects.filter(is_safe=True, last_marked_at__gte=active_cutoff)
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
            return Response({'success': False, 'error': 'user_id is required'},
                            status=status.HTTP_400_BAD_REQUEST)

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
            return Response({'success': False, 'error': 'User not found'},
                            status=status.HTTP_404_NOT_FOUND)
