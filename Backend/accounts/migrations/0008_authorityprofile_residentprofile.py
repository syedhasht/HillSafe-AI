from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


def seed_role_profiles(apps, schema_editor):
    User = apps.get_model('accounts', 'User')
    ResidentProfile = apps.get_model('accounts', 'ResidentProfile')
    AuthorityProfile = apps.get_model('accounts', 'AuthorityProfile')

    for user in User.objects.all():
        model = AuthorityProfile if user.role == 'AUTHORITY' else ResidentProfile
        model.objects.get_or_create(
            user=user,
            defaults={
                'username': user.username,
                'phone_number': user.phone_number,
                'email': user.email or '',
            },
        )


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_user_dark_mode'),
    ]

    operations = [
        migrations.CreateModel(
            name='AuthorityProfile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('username', models.CharField(max_length=150, unique=True)),
                ('phone_number', models.CharField(max_length=20, unique=True)),
                ('email', models.EmailField(blank=True, max_length=254)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='authority_profile', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Authority Login Profile',
                'verbose_name_plural': 'Authority Login Profiles',
                'ordering': ['-updated_at'],
            },
        ),
        migrations.CreateModel(
            name='ResidentProfile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('username', models.CharField(max_length=150)),
                ('phone_number', models.CharField(max_length=20, unique=True)),
                ('email', models.EmailField(blank=True, max_length=254)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='resident_profile', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Resident Login Profile',
                'verbose_name_plural': 'Resident Login Profiles',
                'ordering': ['-updated_at'],
            },
        ),
        migrations.RunPython(seed_role_profiles, migrations.RunPython.noop),
    ]
