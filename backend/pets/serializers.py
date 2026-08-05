from datetime import date
from rest_framework import serializers
from .models import Pet

class PetSerializer(serializers.ModelSerializer):
    age = serializers.SerializerMethodField() # To be able to call the get_age method and include it in the serialized data

    class Meta:
        model = Pet
        fields = ['id', 'household', 'name', 'species', 'breed', 'birthday', 'gotcha_date', 'age', 'allergies', 'existing_conditions', 'photo', 'created_at']
        read_only_fields = ['household', 'created_at']

    def get_age(self, obj):
        if not obj.birthday:
            return None
        today = date.today()
        years = today.year - obj.birthday.year
        had_birthday_this_year = (today.month, today.day) >= (obj.birthday.month, obj.birthday.day)
        if not had_birthday_this_year:
            years -= 1
        return years