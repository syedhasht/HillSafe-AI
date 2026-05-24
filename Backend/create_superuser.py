import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hillsafe_core.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Create superuser if it doesn't exist
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(
        username='admin',
        email='admin@hillsafe.com',
        password='admin123',  # Default password
        role='ADMIN'
    )
    print("SUCCESS: Superuser 'admin' created successfully!")
    print("  Username: admin")
    print("  Email: admin@hillsafe.com")
    print("  Password: admin123")
    print("  Role: ADMIN")
    print("\nWARNING: Change this password in production!")
else:
    print("SUCCESS: Superuser 'admin' already exists.")
