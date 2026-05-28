from django.urls import path
from .views import PredictRiskView, PredictLocationRiskView, ModelStatusView

urlpatterns = [
    path('risk/', PredictRiskView.as_view(), name='predict-risk'),
    path('location-risk/', PredictLocationRiskView.as_view(), name='predict-location-risk'),
    path('status/', ModelStatusView.as_view(), name='model-status'),
]
