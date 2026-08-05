from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Household, HouseholdMembership

admin.site.register(User, UserAdmin)
admin.site.register(Household)
admin.site.register(HouseholdMembership)