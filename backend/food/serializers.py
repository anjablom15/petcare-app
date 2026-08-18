from rest_framework import serializers
from .models import FoodProduct, FoodBag, FeedingSlot, MissedMeal
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone

class FoodProductSerializer(serializers.ModelSerializer):
    remaining_quantity = serializers.SerializerMethodField()
    estimated_finish_date = serializers.SerializerMethodField()

    class Meta:
        model = FoodProduct
        fields = ['id', 'household', 'name', 'brand', 'unit_type', 'typical_package_size', 'typical_price', 'created_at', 'remaining_quantity', 'estimated_finish_date']
        read_only_fields = ['household', 'created_at']

    def get_remaining_quantity(self, product):
        total_purchased = sum(
            (bag.quantity_total for bag in product.bags.all() if bag.finished_early_date is None),
            Decimal('0')
        )
        total_consumed = self._total_consumed(product)
        remaining = total_purchased - total_consumed
        return max(remaining, Decimal('0'))

    def _checkpoint_date(self, product):
        finished_dates = [bag.finished_early_date for bag in product.bags.all() if bag.finished_early_date is not None]
        return max(finished_dates) if finished_dates else None

    def get_estimated_finish_date(self, product):
        daily_rate = self._daily_rate(product, active_only=True)
        if daily_rate <= 0:
            return None

        remaining = self.get_remaining_quantity(product)
        if remaining <= 0:
            return timezone.now().date()

        days_left = float(remaining / daily_rate)
        return timezone.now().date() + timedelta(days=days_left)

    def _daily_rate(self, product, active_only=False):
        today = timezone.now().date()
        rate = Decimal('0')
        for slot in product.feeding_slots.all():
            if active_only and slot.end_date is not None and slot.end_date < today:
                continue
            occurences = len(slot.days_of_week)
            rate += slot.portion_amount * Decimal(occurences) / Decimal(7)
        return rate

    def _total_consumed(self, product):
        today = timezone.now().date()
        checkpoint = self._checkpoint_date(product)
        total = Decimal('0')
        for slot in product.feeding_slots.all():
            start = slot.start_date
            if checkpoint and checkpoint > start:
                start = checkpoint

            end = slot.end_date or today
            if end > today:
                end = today
            if end < start:
                continue

            days_active = max((end - start).days, 0)
            occurrences = len(slot.days_of_week)
            weekly_rate = slot.portion_amount * Decimal(occurrences) / Decimal(7)
            consumed_for_slot = weekly_rate * Decimal(days_active)

            missed_count = slot.missed_meals.filter(date__gte=start, date__lte=end).count()
            consumed_for_slot -= slot.portion_amount * Decimal(missed_count)
            consumed_for_slot = max(consumed_for_slot, Decimal('0'))

            total += consumed_for_slot
        return total

class FoodBagSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodBag
        fields = ['id', 'product', 'purchase_date', 'quantity_total', 'price_paid', 'finished_early_date', 'created_at']
        read_only_fields = ['created_at']

        def validate_product(self, product):
            request = self.context['request']
            if not product.household.memberships.filter(user=request.user).exists():
                raise serializers.ValidationError("You don't have access to this food product")
            return product

class FeedingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedingSlot
        fields = ['id', 'pet', 'product', 'label', 'portion_amount', 'days_of_week', 'start_date', 'end_date', 'created_at']
        read_only_fields = ['created_at']

        def validate_pet(self, pet):
            request = self.context['request']
            if not pet.household.memberships.filter(user=request.user).exists():
                raise serializers.ValidationError("You don't have access to this pet.")
            return pet

        def validate_product(self, product):
            request = self.context['request']
            if not product.household.memberships.filter(user=request.user).exists():
                raise serializers.ValidationError("You don't have access to this food product.")
            return product

class MissedMealSerializer(serializers.ModelSerializer):
    class Meta:
        model = MissedMeal
        fields = ['id', 'feeding_slot', 'date', 'created_at']
        read_only_fields = ['created_at']

    def validate_feeding_slot(self, feeding_slot):
        request = self.context['request']
        if not feeding_slot.pet.household.memberships.filter(user=request.user).exists():
            raise serializers.ValidationError("You don't have access to this feeding slot")
        return feeding_slot    