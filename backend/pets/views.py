from rest_framework import permissions, viewsets
from .models import Pet
from .serializers import PetSerializer
from .permissions import IsHouseholdMember

class PetViewSet(viewsets.ModelViewSet):
    serializer_class = PetSerializer
    permission_classes = [permissions.IsAuthenticated, IsHouseholdMember]

    def get_queryset(self):
        # Return pets that belong to households the user is a member of
        return Pet.objects.filter(household__memberships__user=self.request.user)

    def perform_create(self, serializer):
        membership = self.request.user.household_memberships.first()
        serializer.save(household=membership.household)