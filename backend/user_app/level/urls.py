from django.urls import path
from .views import get_user_level, get_user_promotions, get_next_level

urlpatterns = [
    path('', get_user_level, name='member_level'),
    path('promotions/', get_user_promotions, name='member_promotions'),
    path('next_level/', get_next_level, name='next_level'),
]
