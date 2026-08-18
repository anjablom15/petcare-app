from django.db import models
from django.contrib.postgres.fields import ArrayField
from accounts.models import Household
from pets.models import Pet

class FoodProduct(models.Model):
    UNIT_CHOICES = [
        ('weight', 'Weight (kg)'),
        ('count', 'Count (items)'),
    ]

    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='food_products')
    name = models.CharField(max_length=150)
    brand = models.CharField(max_length=100, blank=True)
    unit_type = models.CharField(max_length=10, choices=UNIT_CHOICES)
    typical_package_size = models.DecimalField(max_digits=8, decimal_places=2)
    typical_price = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.brand} {self.name}".strip()

class FoodBag(models.Model):
    product = models.ForeignKey(FoodProduct, on_delete=models.CASCADE, related_name='bags')
    purchase_date = models.DateField()
    quantity_total = models.DecimalField(max_digits=8, decimal_places=2)
    price_paid = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    finished_early_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product} - {self.quantity_total} bought {self.purchase_date}"

class FeedingSlot(models.Model):
    DAY_CHOICES = [
        ('mon', 'Monday'), ('tue', 'Tuesday'), ('wed', 'Wednesday'), ('thu', 'Thursday'), ('fri', 'Friday'), ('sat', 'Saturday'), ('sun', 'Sunday')
    ]

    pet = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name='feeding_slots')
    product = models.ForeignKey(FoodProduct, on_delete=models.CASCADE, related_name='feeding_slots')
    label = models.CharField(max_length=50, blank=True)
    portion_amount = models.DecimalField(max_digits=8, decimal_places=2)
    days_of_week = ArrayField(models.CharField(max_length=3, choices=DAY_CHOICES))
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['pet', 'start_date']

    def __str__(self):
        return f"{self.pet.name} - {self.label or self.product.name}"

class MissedMeal(models.Model):
    feeding_slot = models.ForeignKey(FeedingSlot, on_delete=models.CASCADE, related_name='missed_meals')
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        unique_together = ['feeding_slot', 'date']

    def __str__(self):
        return f"{self.feeding_slot} missed on {self.date}"

