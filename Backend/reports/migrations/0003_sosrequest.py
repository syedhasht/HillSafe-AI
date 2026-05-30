import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('regions', '0004_region_danger_radius_km_region_is_critical_zone_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('reports', '0002_safetystatus_area_name_safetystatus_latitude_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='SOSRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=150)),
                ('phone_number', models.CharField(blank=True, max_length=20)),
                ('latitude', models.FloatField()),
                ('longitude', models.FloatField()),
                ('area_name', models.CharField(blank=True, max_length=255)),
                ('risk_level', models.CharField(blank=True, max_length=20)),
                ('risk_score', models.FloatField(blank=True, null=True)),
                ('message', models.TextField(default='Emergency SOS. User needs immediate help.')),
                ('status', models.CharField(choices=[('NEEDS_HELP', 'Needs Help'), ('ACKNOWLEDGED', 'Acknowledged'), ('RESOLVED', 'Resolved')], default='NEEDS_HELP', max_length=20)),
                ('timestamp', models.DateTimeField(auto_now_add=True)),
                ('region', models.ForeignKey(blank=True, help_text='Nearest/current risk area for this SOS request', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='sos_requests', to='regions.region')),
                ('user', models.ForeignKey(help_text='User who sent the SOS request', on_delete=django.db.models.deletion.CASCADE, related_name='sos_requests', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'SOS Request',
                'verbose_name_plural': 'SOS Requests',
                'ordering': ['-timestamp'],
            },
        ),
    ]
