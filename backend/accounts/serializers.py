from django.db import transaction
from rest_framework import serializers
from .models import User, Household, HouseholdMembership

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    household_name = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'household_name']

    def create(self, validated_data):
        household_name = validated_data.pop('household_name', None)
        password = validated_data.pop('password')

        # To make sure that the user and household creation is atomic, and nothing is created if an error occurs.
        with transaction.atomic():
            user = User(**validated_data)
            user.set_password(password)
            user.save()

            household = Household.objects.create(name=household_name or f"{user.username}'s Household")
            HouseholdMembership.objects.create(household=household, user=user, role='owner')
        return user
