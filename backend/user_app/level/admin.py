from backend.admin_site import custom_admin_site
from django.contrib import admin
from .models import Level, Promotion


@admin.register(Level, site=custom_admin_site)
class LevelAdmin(admin.ModelAdmin):
    list_display = ('level', 'require_miles', 'require_tickets')  # 显示的字段
    list_filter = ('level',)  # 筛选条件
    search_fields = ('level',)  # 搜索字段


@admin.register(Promotion, site=custom_admin_site)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'start_date', 'end_date', 'level')  # 显示的字段
    list_filter = ('start_date', 'end_date', 'level')  # 筛选条件
    search_fields = ('name',)  # 搜索字段

