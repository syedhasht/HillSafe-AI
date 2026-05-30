from django.db import migrations, models
from django.utils import timezone


def seed_sos_times(apps, schema_editor):
    SOSRequest = apps.get_model('reports', 'SOSRequest')
    for sos in SOSRequest.objects.filter(start_time__isnull=True):
        start_time = sos.timestamp or timezone.now()
        sos.start_time = start_time
        sos.end_time = start_time + timezone.timedelta(minutes=5)
        sos.save(update_fields=['start_time', 'end_time'])


class Migration(migrations.Migration):

    dependencies = [
        ('reports', '0004_incidentreport_location_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='sosrequest',
            name='end_time',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='sosrequest',
            name='start_time',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.RunPython(seed_sos_times, migrations.RunPython.noop),
    ]
