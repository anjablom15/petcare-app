from django.db import models
from accounts.models import Household

class Pet(models.Model):
    SPECIES_CHOICES = [
        ('dog', 'Dog'),
        ('cat', 'Cat'),
        ('bird', 'Bird'),
        ('fish', 'Fish'),
        ('reptile', 'Reptile'),
        ('other', 'Other'),
    ]

    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='pets')
    name = models.CharField(max_length=100)
    species = models.CharField(max_length=20, choices=SPECIES_CHOICES)
    breed = models.CharField(max_length=100, blank=True, null=True)
    birthday = models.DateField(blank=True, null=True)
    gotcha_date = models.DateField(blank=True, null=True)
    allergies = models.TextField(blank=True)
    existing_conditions = models.TextField(blank=True)
    photo = models.ImageField(upload_to='pet_photos/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name