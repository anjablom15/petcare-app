from rest_framework import serializers
from .models import WeightLog

class WeightLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeightLog
        fields = ['id', 'pet', 'weight_kg', 'date', 'notes', 'created_at']
        read_only_fields = ['created_at']

    def validate_pet(self,pet):
        request = self.context['request']
        if not pet.household.memberships.filter(user=request.user).exists():
            raise serializers.ValidationError("You do not have access to this pet.")
        return pet 