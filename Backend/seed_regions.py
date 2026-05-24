import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from regions.models import Region

regions_data = [
    {"name": "Murree", "district": "Rawalpindi", "lat": 33.9078, "lng": 73.3915, "risk": 0.85},
    {"name": "Swat", "district": "Swat", "lat": 35.2227, "lng": 72.4258, "risk": 0.65},
    {"name": "Abbottabad", "district": "Abbottabad", "lat": 34.1688, "lng": 73.2215, "risk": 0.45},
    {"name": "Mansehra", "district": "Mansehra", "lat": 34.3333, "lng": 73.2000, "risk": 0.30},
    {"name": "Kohistan", "district": "Upper Kohistan", "lat": 35.2500, "lng": 73.5000, "risk": 0.90},
    {"name": "Chitral", "district": "Lower Chitral", "lat": 35.8510, "lng": 71.7864, "risk": 0.25},
    {"name": "Gilgit", "district": "Gilgit", "lat": 35.9208, "lng": 74.3089, "risk": 0.55},
    {"name": "Hunza", "district": "Hunza", "lat": 36.3167, "lng": 74.6500, "risk": 0.40},
    {"name": "Skardu", "district": "Skardu", "lat": 35.2971, "lng": 75.6333, "risk": 0.35},
    {"name": "Neelum Valley", "district": "Neelum", "lat": 34.5857, "lng": 73.9070, "risk": 0.75},
]

print("Starting region seeding...")
for data in regions_data:
    obj, created = Region.objects.update_or_create(
        name=data["name"],
        defaults={
            "district": data["district"],
            "latitude": data["lat"],
            "longitude": data["lng"],
            "current_risk_score": data["risk"]
        }
    )
    action = "Created" if created else "Updated"
    print(f"{action}: {obj.name} ({obj.district}) - Risk: {obj.current_risk_score}")

print("Seeding complete!")
