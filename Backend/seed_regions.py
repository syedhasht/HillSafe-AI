import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from regions.models import Region

regions_data = [
    {"name": "Murree", "district": "Rawalpindi", "lat": 33.9078, "lng": 73.3915, "risk": 0.85, "danger_radius_km": 8, "warning_radius_km": 20},
    {"name": "Swat", "district": "Swat", "lat": 35.2227, "lng": 72.4258, "risk": 0.65, "danger_radius_km": 8, "warning_radius_km": 20},
    {"name": "Abbottabad", "district": "Abbottabad", "lat": 34.1688, "lng": 73.2215, "risk": 0.45, "danger_radius_km": 5, "warning_radius_km": 15},
    {"name": "Mansehra", "district": "Mansehra", "lat": 34.3333, "lng": 73.2000, "risk": 0.30, "danger_radius_km": 5, "warning_radius_km": 15},
    {"name": "Kohistan", "district": "Upper Kohistan", "lat": 35.2500, "lng": 73.5000, "risk": 0.90, "danger_radius_km": 12, "warning_radius_km": 30},
    {"name": "Chitral", "district": "Lower Chitral", "lat": 35.8510, "lng": 71.7864, "risk": 0.25, "danger_radius_km": 8, "warning_radius_km": 20},
    {"name": "Gilgit", "district": "Gilgit", "lat": 35.9208, "lng": 74.3089, "risk": 0.55, "danger_radius_km": 8, "warning_radius_km": 20},
    {"name": "Hunza", "district": "Hunza", "lat": 36.3167, "lng": 74.6500, "risk": 0.40, "danger_radius_km": 10, "warning_radius_km": 25},
    {"name": "Skardu", "district": "Skardu", "lat": 35.2971, "lng": 75.6333, "risk": 0.35, "danger_radius_km": 8, "warning_radius_km": 20},
    {"name": "Neelum Valley", "district": "Neelum", "lat": 34.5857, "lng": 73.9070, "risk": 0.75, "danger_radius_km": 10, "warning_radius_km": 25},
]

print("Starting region seeding...")
for data in regions_data:
    obj, created = Region.objects.get_or_create(
        name=data["name"],
        district=data["district"],
        defaults={
            "district": data["district"],
            "latitude": data["lat"],
            "longitude": data["lng"],
            "current_risk_score": data["risk"],
            "is_critical_zone": True,
            "danger_radius_km": data["danger_radius_km"],
            "warning_radius_km": data["warning_radius_km"],
        }
    )
    if not created:
        Region.objects.filter(pk=obj.pk).update(
            district=data["district"],
            latitude=data["lat"],
            longitude=data["lng"],
            is_critical_zone=True,
            danger_radius_km=data["danger_radius_km"],
            warning_radius_km=data["warning_radius_km"],
        )
        obj.refresh_from_db()
    action = "Created" if created else "Updated"
    print(f"{action}: {obj.name} ({obj.district}) - Risk preserved at: {obj.current_risk_score}")

print("Seeding complete!")
