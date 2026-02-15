from django.urls import path
from .views import SaveDeviceTokenView

urlpatterns = [
    path('save-device-token/', SaveDeviceTokenView.as_view(), name='save-device-token'),
]
