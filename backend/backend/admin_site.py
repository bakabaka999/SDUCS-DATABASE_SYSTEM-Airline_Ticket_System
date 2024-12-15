from django.contrib.admin import AdminSite


class CustomAdminSite(AdminSite):
    site_header = "航空票务与用户管理后台"
    site_title = "航班 & 用户管理"
    index_title = "欢迎进入航空票务管理后台"

    def get_app_list(self, request):
        app_list = super().get_app_list(request)
        # 自定义分类
        custom_app_order = {
            "用户与订单管理": ["User", "Passenger", "Order"],
            "航班管理": ["Flight", "Plane", "Airport", "City", "Ticket"],
            "等级制度与活动管理": ["Level", "Promotion"],
            "乘客证件管理": ["Document"],
            "数据统计与分析": [],  # 特别添加统计功能分组
        }
        new_app_list = []

        for custom_app_name, models in custom_app_order.items():
            custom_models = []
            for app in app_list:
                for model in app["models"]:
                    if model["object_name"] in models:
                        custom_models.append(model)
            # 如果是统计功能分组，手动添加自定义url
            if custom_app_name == "数据统计与分析":
                custom_models.append({
                    "name": "数据统计",
                    "object_name": "Analytics",
                    "admin_url": "/admin/analytics/",
                    "add_url": None,
                })

            if custom_models:
                new_app_list.append({
                    "name": custom_app_name,
                    "app_label": custom_app_name,
                    "models": custom_models
                })

        return new_app_list


# 创建实例
custom_admin_site = CustomAdminSite(name='custom_admin')
