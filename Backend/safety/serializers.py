from rest_framework import serializers

from .models import EmergencyContact, SavedSafetyTip


class SavedSafetyTipSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = SavedSafetyTip
        fields = [
            'id',
            'user',
            'user_name',
            'tip_id',
            'tip_title',
            'tip_description',
            'saved_at',
        ]
        read_only_fields = ['id', 'user', 'user_name', 'saved_at']


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ['id', 'name', 'number', 'description', 'icon', 'sort_order']
