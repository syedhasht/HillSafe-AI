from django.urls import path
from .views import SubmitReportView, MarkSafeView, RegionStatsView, MyReportsView, ReportListView, ReportReviewView, ActiveReportZonesView, SubmitSOSView, SOSListView, SOSStatusView, ClearSafetyStatusView, ClearSOSView, ClearReportsView

urlpatterns = [
    path('submit/', SubmitReportView.as_view(), name='submit-report'),
    path('mark-safe/', MarkSafeView.as_view(), name='mark-safe'),
    path('stats/<int:region_id>/', RegionStatsView.as_view(), name='region-stats'),
    path('my-reports/', MyReportsView.as_view(), name='my-reports'),
    path('list/', ReportListView.as_view(), name='list-reports'),
    path('active-zones/', ActiveReportZonesView.as_view(), name='active-report-zones'),
    path('<int:report_id>/review/', ReportReviewView.as_view(), name='review-report'),
    path('sos/', SubmitSOSView.as_view(), name='submit-sos'),
    path('sos/status/', SOSStatusView.as_view(), name='sos-status'),
    path('sos/list/', SOSListView.as_view(), name='list-sos'),
    path('safety-status/clear/', ClearSafetyStatusView.as_view(), name='clear-safety-status'),
    path('sos/clear/', ClearSOSView.as_view(), name='clear-sos'),
    path('clear/', ClearReportsView.as_view(), name='clear-reports'),
]
