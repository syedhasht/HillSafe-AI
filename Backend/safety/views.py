from rest_framework import permissions, status
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EmergencyContact, SavedSafetyTip
from .serializers import EmergencyContactSerializer, SavedSafetyTipSerializer


class SavedSafetyTipListCreateView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        tips = SavedSafetyTip.objects.filter(user=request.user)
        serializer = SavedSafetyTipSerializer(tips, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        tip_id = str(request.data.get('tip_id') or '').strip()
        tip_title = str(request.data.get('tip_title') or '').strip()
        tip_description = str(request.data.get('tip_description') or '').strip()

        if not tip_id or not tip_title or not tip_description:
            return Response(
                {'error': 'tip_id, tip_title, and tip_description are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        saved_tip, _ = SavedSafetyTip.objects.update_or_create(
            user=request.user,
            tip_id=tip_id[:80],
            defaults={
                'tip_title': tip_title[:180],
                'tip_description': tip_description,
            },
        )

        serializer = SavedSafetyTipSerializer(saved_tip)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class SavedSafetyTipDeleteView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, tip_id):
        SavedSafetyTip.objects.filter(user=request.user, tip_id=tip_id).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class EmergencyContactListView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        contacts = EmergencyContact.objects.filter(is_active=True)
        if not contacts.exists():
            contacts = _default_contacts()
            return Response(contacts, status=status.HTTP_200_OK)

        serializer = EmergencyContactSerializer(contacts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


def _default_contacts():
    return [
        {
            'id': 1,
            'name': 'Rescue 1122',
            'number': '1122',
            'description': 'Emergency Rescue Services',
            'icon': 'ambulance',
            'sort_order': 1,
        },
        {
            'id': 2,
            'name': 'Police',
            'number': '15',
            'description': 'Police Emergency',
            'icon': 'shield',
            'sort_order': 2,
        },
        {
            'id': 3,
            'name': 'Fire Brigade',
            'number': '16',
            'description': 'Fire Emergency',
            'icon': 'flame',
            'sort_order': 3,
        },
    ]
