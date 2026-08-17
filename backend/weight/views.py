from rest_framework import viewsets, permissions
from .models import WeightLog
from .serializers import WeightLogSerializer
from .permissions import IsHouseholdMemberForWeightLog

class WeightLogViewSet(viewsets.ModelViewSet):
    serializer_class = WeightLogSerializer
    permissions_class = [permissions.IsAuthenticated, IsHouseholdMemberForWeightLog]

    def get_queryset(self):
        queryset = WeightLog.objects.filter(pet__household__memberships__user=self.request.user)
        pet_id = self.request.query_params.get('pet')
        if pet_id is not None:
            queryset = queryset.filter(pet_id=pet_id)
        return queryset
