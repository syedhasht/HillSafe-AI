from django.urls import path
from .views import PredictRiskView, ModelStatusView

urlpatterns = [
    path('risk/', PredictRiskView.as_view(), name='predict-risk'),
    path('status/', ModelStatusView.as_view(), name='model-status'),
]
