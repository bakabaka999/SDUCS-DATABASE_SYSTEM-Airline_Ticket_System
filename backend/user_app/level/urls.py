from django.urls import path
from .views import get_user_level

urlpatterns = [
    path('', get_user_level, name='member_level'),
]
