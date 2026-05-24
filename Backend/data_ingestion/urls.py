from django.urls import path
from .views import TriggerIngestionView

urlpatterns = [
    path('trigger/', TriggerIngestionView.as_view(), name='data-ingestion-trigger'),
]
