from django.urls import path
from .views import ProfileView, SaveDeviceTokenView

urlpatterns = [
    path('profile/', ProfileView.as_view(), name='profile'),
    path('save-device-token/', SaveDeviceTokenView.as_view(), name='save-device-token'),
]
