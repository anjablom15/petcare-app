from rest_framework import permissions

class IsHouseholdMemberForFoodProduct(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.household.memberships.filter(user=request.user).exists()

class IsHouseholdMemberForFoodBag(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.product.household.memberships.filter(user=request.user).exists()

class IsHouseholdMemberForFeedingSlot(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.pet.household.memberships.filter(user=request.user).exists()

class IsHouseholdMemberForMissedMeal(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.feeding_slot.pet.household.memberships.filter(user=request.user).exists()
    