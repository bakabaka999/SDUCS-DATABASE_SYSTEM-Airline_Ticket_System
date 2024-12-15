from django.apps import AppConfig


class AccountConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'user_app.account'
    verbose_name = "用户与乘客管理"  # 自定义分组名称
