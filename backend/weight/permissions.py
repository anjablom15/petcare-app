from rest_framework import permissions

class IsHouseholdMemberForWeightLog(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.pet.household.memberships.filter(user=request.user).exists()