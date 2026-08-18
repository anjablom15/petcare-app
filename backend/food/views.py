from rest_framework import viewsets, permissions
from .models import FoodProduct, FoodBag, FeedingSlot, MissedMeal
from .serializers import FoodProductSerializer, FoodBagSerializer,FeedingSlotSerializer, MissedMealSerializer
from .permissions import IsHouseholdMemberForFoodBag, IsHouseholdMemberForFoodProduct, IsHouseholdMemberForFeedingSlot, IsHouseholdMemberForMissedMeal

class FoodProductViewSet(viewsets.ModelViewSet):
    serializer_class = FoodProductSerializer
    permissions_class = [permissions.IsAuthenticated, IsHouseholdMemberForFoodProduct]

    def get_queryset(self):
        return FoodProduct.objects.filter(household__memberships__user=self.request.user)

    def perform_create(self, serializer):
        membership = self.request.user.household_memberships.first()
        serializer.save(household=membership.household)

class FoodBagViewSet(viewsets.ModelViewSet):
    serializer_class = FoodBagSerializer
    permissions_class = [permissions.IsAuthenticated, IsHouseholdMemberForFoodBag]

    def get_queryset(self):
        queryset = FoodBag.objects.filter(product__household__memberships__user=self.request.user)
        product_id = self.request.query_params.get('product')
        if product_id is not None:
            queryset = queryset.filter(product_id=product_id)
        return queryset

class FeedingSlotViewSet(viewsets.ModelViewSet):
    serializer_class = FeedingSlotSerializer
    permissions_class = [permissions.IsAuthenticated, IsHouseholdMemberForFeedingSlot]

    def get_queryset(self):
        queryset = FeedingSlot.objects.filter(pet__household__memberships__user=self.request.user)
        pet_id = self.request.query_params.get('pet')
        if pet_id is not None:
            queryset = queryset.filter(pet_id=pet_id)
        return queryset

class MissedMealViewSet(viewsets.ModelViewSet):
    serializer_class = MissedMealSerializer
    permissions_class = [permissions.IsAuthenticated, IsHouseholdMemberForMissedMeal]

    def get_queryset(self):
        queryset = MissedMeal.objects.filter(feeding_slot__pet__household__memberships__user=self.request.user)
        slot_id = self.request.query_params.get('feeding_slot')
        if slot_id is not None:
            queryset = queryset.filter(slot_id=slot_id)
        return queryset