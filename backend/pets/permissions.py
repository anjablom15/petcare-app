from rest_framework import permissions

class IsHouseholdMember(permissions.BasePermission):
    """
    Custom permission to only allow members of a household to access its pets.
    """

    def has_object_permission(self, request, view, obj):
        # Check if the user is a member of the household associated with the pet
        return obj.household.memberships.filter(user=request.user).exists()