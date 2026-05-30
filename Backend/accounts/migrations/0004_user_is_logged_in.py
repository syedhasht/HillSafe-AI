from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_user_is_safe_user_location_region_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='is_logged_in',
            field=models.BooleanField(
                default=False,
                help_text='Whether the user currently has an active app login',
            ),
        ),
    ]
