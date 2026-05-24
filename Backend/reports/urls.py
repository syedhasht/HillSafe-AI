from django.urls import path
from .views import SubmitReportView, MarkSafeView, RegionStatsView, MyReportsView, ReportListView

urlpatterns = [
    path('submit/', SubmitReportView.as_view(), name='submit-report'),
    path('mark-safe/', MarkSafeView.as_view(), name='mark-safe'),
    path('stats/<int:region_id>/', RegionStatsView.as_view(), name='region-stats'),
    path('my-reports/', MyReportsView.as_view(), name='my-reports'),
    path('list/', ReportListView.as_view(), name='list-reports'),
]
