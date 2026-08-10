from django.contrib.auth.models import AbstractUser
from django.conf import settings
from django.db import models

class User(AbstractUser):
    pass

class Household(models.Model):
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class HouseholdMembership(models.Model):
    ROLE_CHOICES = [
        ('owner', 'Owner'),
        ('member', 'Member'),
    ]

    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='memberships')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='household_memberships')
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='member')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('household', 'user')

    def __str__(self):
        return f"{self.user} in {self.household} ({self.role})"