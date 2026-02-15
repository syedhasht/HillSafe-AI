"""
Django management command to seed the database with demo data.
Usage: python manage.py seed_db
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from regions.models import Region
from alerts.models import Alert

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed the database with demo users, regions, and alerts for testing'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.WARNING('Starting database seeding...'))
        
        # Clear existing data
        self.stdout.write('Clearing existing data...')
        Alert.objects.all().delete()
        Region.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()  # Keep superuser
        self.stdout.write(self.style.SUCCESS('  - Cleared alerts, regions, and non-admin users'))
        
        # Create Users
        self.stdout.write('\nCreating demo users...')
        
        # Super Admin
        admin, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@hillsafe.com',
                'role': 'ADMIN',
                'is_staff': True,
                'is_superuser': True,
            }
        )
        if created or not admin.has_usable_password():
            admin.set_password('admin123')
            admin.save()
        self.stdout.write(self.style.SUCCESS('  - Super Admin: admin / admin123 (ADMIN)'))
        
        # Authority User
        official, created = User.objects.get_or_create(
            username='official',
            defaults={
                'email': 'official@hillsafe.com',
                'role': 'AUTHORITY',
                'phone_number': '1122',
                'is_staff': False,
            }
        )
        if created or not official.has_usable_password():
            official.set_password('pass123')
            official.save()
        self.stdout.write(self.style.SUCCESS('  - Authority: official / pass123 (AUTHORITY)'))
        
        # Community User
        resident, created = User.objects.get_or_create(
            username='resident',
            defaults={
                'email': 'resident@hillsafe.com',
                'role': 'COMMUNITY',
                'phone_number': '03001234567',
                'is_staff': False,
            }
        )
        if created or not resident.has_usable_password():
            resident.set_password('pass123')
            resident.save()
        self.stdout.write(self.style.SUCCESS('  - Resident: resident / pass123 (COMMUNITY)'))
        
        # Create Regions
        self.stdout.write('\nCreating demo regions...')
        
        murree = Region.objects.create(
            name='Murree',
            district='Rawalpindi',
            latitude=33.907,
            longitude=73.394,
            current_risk_score=0.8
        )
        self.stdout.write(self.style.SUCCESS('  - Murree (Risk: 0.8)'))
        
        swat = Region.objects.create(
            name='Swat Valley',
            district='Swat',
            latitude=35.222,
            longitude=72.425,
            current_risk_score=0.4
        )
        self.stdout.write(self.style.SUCCESS('  - Swat Valley (Risk: 0.4)'))
        
        naran = Region.objects.create(
            name='Naran',
            district='Mansehra',
            latitude=34.909,
            longitude=73.649,
            current_risk_score=0.2
        )
        self.stdout.write(self.style.SUCCESS('  - Naran (Risk: 0.2)'))
        
        # Create Alerts
        self.stdout.write('\nCreating demo alerts...')
        
        Alert.objects.create(
            region=murree,
            severity='HIGH',
            message='Heavy rainfall detected. Landslide imminent near Mall Road.',
            is_active=True
        )
        self.stdout.write(self.style.SUCCESS('  - HIGH alert for Murree'))
        
        # Summary
        self.stdout.write('\n' + '=' * 60)
        self.stdout.write(self.style.SUCCESS('Database seeding completed successfully!'))
        self.stdout.write('=' * 60)
        self.stdout.write(f'\nCreated:')
        self.stdout.write(f'  Users: {User.objects.count()}')
        self.stdout.write(f'  Regions: {Region.objects.count()}')
        self.stdout.write(f'  Active Alerts: {Alert.objects.filter(is_active=True).count()}')
        self.stdout.write('\nDemo Credentials:')
        self.stdout.write('  admin / admin123 (ADMIN)')
        self.stdout.write('  official / pass123 (AUTHORITY)')
        self.stdout.write('  resident / pass123 (COMMUNITY)')
        self.stdout.write('\n' + '=' * 60)
