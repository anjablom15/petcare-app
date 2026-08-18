from rest_framework.routers import DefaultRouter
from .views import FoodProductViewSet, FoodBagViewSet, FeedingSlotViewSet, MissedMealViewSet

router = DefaultRouter()
router.register('food-products', FoodProductViewSet, basename='foodproduct')
router.register('food-bags', FoodBagViewSet, basename='foodbag')
router.register('feeding-slots', FeedingSlotViewSet, basename='feedingslot')
router.register('missed-meals', MissedMealViewSet, basename='missedmeal')

urlpatterns = router.urls