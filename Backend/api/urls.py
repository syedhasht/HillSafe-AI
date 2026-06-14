from django.urls import path
from django.http import JsonResponse
from .views import (
    CustomLoginView, CustomLogoutView, AuthoritySignupView, RegionListView,
    AlertListView, CreateAlertView, AnalyticsView,
    SensorDataView, DistrictsView, SafetyStatusView,
    MarkSafeView, HillSafeChatbotView, ClearAlertsView,
)
from .analytics_views import AnalyticsDetailView


def api_index(request):
    return JsonResponse({"message": "HillSafe-AI API Endpoints", "status": "online"})


urlpatterns = [
    path('', api_index, name='api-index'),
    path('login/', CustomLoginView.as_view(), name='api-login'),
    path('logout/', CustomLogoutView.as_view(), name='api-logout'),
    path('signup/authority/', AuthoritySignupView.as_view(), name='api-authority-signup'),
    path('regions/', RegionListView.as_view(), name='api-regions'),
    path('alerts/', AlertListView.as_view(), name='api-alerts'),
    path('alerts/create/', CreateAlertView.as_view(), name='api-alerts-create'),
    # Real-data analytics (replaces random-number AnalyticsView for the app)
    path('analytics/', AnalyticsDetailView.as_view(), name='api-analytics'),
    path('sensor-data/', SensorDataView.as_view(), name='api-sensor-data'),
    path('districts/', DistrictsView.as_view(), name='api-districts'),
    path('safety-status/', SafetyStatusView.as_view(), name='api-safety-status'),
    path('mark-safe/', MarkSafeView.as_view(), name='api-mark-safe'),
    path('chatbot/', HillSafeChatbotView.as_view(), name='api-chatbot'),
    path('alerts/clear/', ClearAlertsView.as_view(), name='clear-alerts'),
]
