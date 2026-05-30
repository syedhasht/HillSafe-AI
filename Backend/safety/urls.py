from django.urls import path

from .views import (
    EmergencyContactListView,
    SavedSafetyTipDeleteView,
    SavedSafetyTipListCreateView,
)

urlpatterns = [
    path('saved-tips/', SavedSafetyTipListCreateView.as_view(), name='saved-safety-tips'),
    path('saved-tips/<str:tip_id>/', SavedSafetyTipDeleteView.as_view(), name='delete-saved-safety-tip'),
    path('emergency-contacts/', EmergencyContactListView.as_view(), name='emergency-contacts'),
]
