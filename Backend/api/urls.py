from django.urls import path
from django.http import JsonResponse
from .views import CustomLoginView, RegionListView, AlertListView, AnalyticsView, SensorDataView, DistrictsView, SafetyStatusView, MarkSafeView

def api_index(request):
    return JsonResponse({"message": "HillSafe-AI API Endpoints", "status": "online"})

urlpatterns = [
    path('', api_index, name='api-index'),
    path('login/', CustomLoginView.as_view(), name='api-login'),
    path('regions/', RegionListView.as_view(), name='api-regions'),
    path('alerts/', AlertListView.as_view(), name='api-alerts'),
    path('analytics/', AnalyticsView.as_view(), name='api-analytics'),
    path('sensor-data/', SensorDataView.as_view(), name='api-sensor-data'),
    path('districts/', DistrictsView.as_view(), name='api-districts'),
    path('safety-status/', SafetyStatusView.as_view(), name='api-safety-status'),
    path('mark-safe/', MarkSafeView.as_view(), name='api-mark-safe'),
]
