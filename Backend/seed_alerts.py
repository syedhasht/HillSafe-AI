import os
import django
from datetime import datetime, timedelta
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from regions.models import Region
from alerts.models import Alert
from django.utils import timezone

# Get all regions
regions = list(Region.objects.all())

if not regions:
    print("No regions found! Please run seed_regions.py first.")
    exit(1)

# Sample alert messages and types
alert_templates = [
    {
        "severity": "CRITICAL",
        "message": "Immediate evacuation warning: Severe landslide detected in {region}. Move to safe zones immediately.",
        "active_prob": 0.2
    },
    {
        "severity": "HIGH",
        "message": "High landslide risk in {region} due to heavy rainfall. Avoid travel on mountain roads.",
        "active_prob": 0.4
    },
    {
        "severity": "MEDIUM",
        "message": "Moderate landslide warning for {region}. Monitor local news and weather updates.",
        "active_prob": 0.6
    },
    {
        "severity": "LOW",
        "message": "Low risk of landslides in {region}. Roads are open but exercise caution.",
        "active_prob": 0.8
    }
]

print("Starting alert seeding...")

# Create 20 historical alerts over the last 30 days
for i in range(20):
    region = random.choice(regions)
    template = random.choice(alert_templates)
    
    # Random time in last 30 days
    days_ago = random.randint(0, 30)
    hours_ago = random.randint(0, 23)
    minutes_ago = random.randint(0, 59)
    
    timestamp = timezone.now() - timedelta(days=days_ago, hours=hours_ago, minutes=minutes_ago)
    
    # Determine if active based on probability and age (older alerts less likely to be active)
    is_active = random.random() < template["active_prob"]
    if days_ago > 7:
        is_active = False
        
    resolved_at = None
    if not is_active:
        resolved_at = timestamp + timedelta(hours=random.randint(4, 48))

    alert = Alert.objects.create(
        region=region,
        severity=template["severity"],
        message=template["message"].format(region=region.name),
        affected_population=random.randint(100, 5000),
        is_active=is_active,
        timestamp=timestamp, # Note: auto_now_add might override this on creation, we might need to update
        resolved_at=resolved_at
    )
    
    # Fix timestamp since auto_now_add sets it to now()
    Alert.objects.filter(id=alert.id).update(timestamp=timestamp)
    
    status = "Active" if is_active else "Resolved"
    print(f"Created: [{status}] {alert.severity} alert for {region.name} - {days_ago} days ago")

print("Seeding complete! 20 alerts created.")
