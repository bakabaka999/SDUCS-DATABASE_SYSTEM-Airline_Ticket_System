from django.contrib import admin
from .models import User, Passenger
from backend.admin_site import custom_admin_site


# 用户模型的 Admin 配置
@admin.register(User, site=custom_admin_site)
class UserAdmin(admin.ModelAdmin):
    list_display = ('name', 'email', 'phone_number', 'accumulated_miles', 'ticked_count')  # 显示字段
    search_fields = ('name', 'email', 'phone_number')  # 搜索字段
    list_filter = ('accumulated_miles', 'ticked_count')  # 筛选字段
    actions = ['freeze_user', 'unfreeze_user', 'delete_selected_users']  # 自定义操作

    # 去除默认删除权限
    def has_delete_permission(self, request, obj=None):
        return False  # 禁用默认删除功能

    # 冻结账户操作
    @admin.action(description='冻结选中的用户账户')
    def freeze_user(self, request, queryset):
        queryset.update(password='FROZEN')  # 简单冻结逻辑，可以自定义
        self.message_user(request, "选中的用户已被冻结")

    # 解冻账户操作
    @admin.action(description='解冻选中的用户账户')
    def unfreeze_user(self, request, queryset):
        # 假设冻结标记为 "FROZEN"，恢复默认密码（实际生产中需调整逻辑）
        queryset.update(password='DEFAULT_PASSWORD')
        self.message_user(request, "选中的用户已被解冻")

        # 自定义删除用户操作

    @admin.action(description='删除选中的用户')
    def delete_selected_users(self, request, queryset):
        # 遍历选中的用户，逐一删除对应的 Django 内部用户
        for user in queryset:
            # 假设内部用户模型是 Django 内置 User 模型
            from django.contrib.auth.models import User as InternalUser

            # 根据某个字段（如 email）找到内部用户并删除
            try:
                internal_user = InternalUser.objects.get(email=user.email)
                internal_user.delete()  # 删除内部用户
            except InternalUser.DoesNotExist:
                self.message_user(request, f"未找到与 {user.email} 关联的内部用户", level='warning')

            # 删除自定义用户
            user.delete()

        self.message_user(request, "选中的用户及其关联的内部用户已被删除")


# 乘客模型的 Admin 配置
@admin.register(Passenger, site=custom_admin_site)
class PassengerAdmin(admin.ModelAdmin):
    list_display = ('name', 'gender', 'phone_number', 'email', 'person_type', 'birth_date')
    search_fields = ('name', 'phone_number', 'email')
    list_filter = ('person_type', 'gender')

