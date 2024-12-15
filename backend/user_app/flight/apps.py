from django.apps import AppConfig


class FlightConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'user_app.flight'
    verbose_name = "航班与机票管理"  # 自定义分组名称
