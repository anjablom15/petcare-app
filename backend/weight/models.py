from django.db import models
from pets.models import Pet

class WeightLog(models.Model):
    pet = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name='weight_logs')
    weight_kg = models.DecimalField(max_digits=5, decimal_places=2)
    date = models.DateField()
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f"{self.pet.name} - {self.weight_kg}kg on {self.date}"
