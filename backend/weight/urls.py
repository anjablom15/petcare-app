from rest_framework.routers import DefaultRouter
from .views import WeightLogViewSet

router = DefaultRouter()
router.register('weight-logs', WeightLogViewSet, basename='weightlog')

urlpatterns = router.urls