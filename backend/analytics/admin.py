from django.urls import path
from django.template.response import TemplateResponse
from django.db.models import Count, Sum, OuterRef, Subquery, IntegerField
from django.http import HttpResponse
import pandas as pd
import io
import base64

from user_app.account.models import User, Passenger
from user_app.flight.models import Flight, Ticket, Order

import matplotlib
matplotlib.use('Agg')  # 使用无图形界面后端

import matplotlib.pyplot as plt
from matplotlib import rcParams

# 设置中文字体
rcParams['font.sans-serif'] = ['SimHei']
rcParams['axes.unicode_minus'] = False


class AnalyticsAdmin:
    """自定义统计功能"""

    def get_custom_urls(self):
        """挂载自定义 URL"""
        return [
            path('analytics/', self.statistics_view, name='custom_analytics'),
        ]

    @staticmethod
    def _convert_to_base64():
        """将图表保存为 Base64"""
        buffer = io.BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        return f"data:image/png;base64,{base64.b64encode(image_png).decode('utf-8')}"

    # 1. 订单趋势图
    @staticmethod
    def generate_order_trend_chart():
        orders_by_date = (
            Order.objects.filter(status='confirmed')
            .values('purchase_time__date')
            .annotate(order_count=Count('order_id'))
            .order_by('purchase_time__date')
        )
        dates = [o['purchase_time__date'] for o in orders_by_date]
        counts = [o['order_count'] for o in orders_by_date]

        plt.figure(figsize=(8, 4))
        plt.plot(dates, counts, marker='o', label="订单数", color="blue")
        plt.title("订单趋势图")
        plt.xlabel("日期")
        plt.ylabel("订单数")
        plt.xticks(rotation=45)
        plt.legend()
        plt.tight_layout()
        return AnalyticsAdmin._convert_to_base64()

    # 2. 每日收入趋势图
    @staticmethod
    def generate_revenue_trend_chart():
        """生成每日收入趋势图"""
        revenue_by_date = (
            Order.objects.filter(status='confirmed')
            .extra({'day': "date(purchase_time)"})
            .values('day')
            .annotate(total_revenue=Sum('total_price'))
            .order_by('day')
        )

        # 清洗数据，确保数据中无 None 值
        dates = []
        revenues = []
        for r in revenue_by_date:
            if r['day'] and r['total_revenue'] is not None:  # 排除无效数据
                dates.append(r['day'])
                revenues.append(r['total_revenue'])
            else:
                # 记录无效数据日志，或忽略
                print(f"无效数据: {r}")

        plt.figure(figsize=(8, 4))
        plt.bar(dates, revenues, color="green")
        plt.title("每日收入趋势")
        plt.xlabel("日期")
        plt.ylabel("收入 (￥)")
        plt.xticks(rotation=45)
        plt.tight_layout()
        return AnalyticsAdmin._convert_to_base64()

    # 3. 乘客类型分布图
    @staticmethod
    def generate_passenger_type_chart():
        passenger_counts = Passenger.objects.values('person_type').annotate(count=Count('id'))
        labels = [dict(Passenger.PERSON_TYPE_CHOICES).get(p['person_type']) for p in passenger_counts]
        sizes = [p['count'] for p in passenger_counts]

        plt.figure(figsize=(6, 6))
        plt.pie(sizes, labels=labels, autopct='%1.1f%%', startangle=140)
        plt.title("乘客类型分布")
        plt.tight_layout()
        return AnalyticsAdmin._convert_to_base64()

    # 4. 热门航班收入统计
    @staticmethod
    def generate_top_flight_revenue_chart():
        flight_revenue = (
            Order.objects.filter(status='confirmed')
            .values('ticket__flight__flight_id')
            .annotate(total_revenue=Sum('total_price'))
            .order_by('-total_revenue')[:5]
        )
        flight_ids = [f['ticket__flight__flight_id'] for f in flight_revenue]
        revenues = [f['total_revenue'] for f in flight_revenue]

        plt.figure(figsize=(8, 4))
        plt.bar(flight_ids, revenues, color='orange')
        plt.title("前五名航班总收入统计")
        plt.xlabel("航班号")
        plt.ylabel("总收入 (￥)")
        plt.tight_layout()
        return AnalyticsAdmin._convert_to_base64()

    # 5. 用户购票频率图
    @staticmethod
    def generate_user_ticket_frequency_chart():
        # 子查询：统计每个用户通过乘客关联的订单数量
        orders_subquery = (
            Order.objects.filter(
                passenger__users__user_id=OuterRef('pk')  # 通过关联的 UserPassengerRelation
            )
            .values('passenger__users__user_id')  # 按用户 ID 分组
            .annotate(total_orders=Count('order_id'))  # 统计订单数
            .values('total_orders')  # 提取订单数
        )

        # 主查询：将子查询的统计值注入 User 表
        user_ticket_counts = (
            User.objects.annotate(
                ticket_count=Subquery(
                    orders_subquery,
                    output_field=IntegerField()  # 正确传入字段类型为类，而非实例
                )
            )
            .values('name', 'ticket_count')  # 选择要返回的字段
            .order_by('-ticket_count')[:10]  # 排序并取前10名
        )

        # 提取用户和票数数据
        users = [u['name'] for u in user_ticket_counts]
        counts = [u['ticket_count'] or 0 for u in user_ticket_counts]  # 防止 None 值

        plt.figure(figsize=(8, 4))
        plt.bar(users, counts, color='purple')
        plt.title("用户购票频率统计 (前十名用户)")
        plt.xlabel("用户名")
        plt.ylabel("购票次数")
        plt.xticks(rotation=45)
        plt.tight_layout()
        return AnalyticsAdmin._convert_to_base64()

    # 统计视图
    @staticmethod
    def statistics_view(request):
        stats = {
            'total_users': User.objects.count(),
            'total_orders': Order.objects.count(),
            'total_sales': Order.objects.filter(status='confirmed').aggregate(Sum('total_price'))['total_price__sum'] or 0,
            'total_flights': Flight.objects.count(),
        }

        return TemplateResponse(request, "admin/analytics.html", {
            'stats': stats,
            'order_trend_chart': AnalyticsAdmin.generate_order_trend_chart(),
            'revenue_trend_chart': AnalyticsAdmin.generate_revenue_trend_chart(),
            'passenger_type_chart': AnalyticsAdmin.generate_passenger_type_chart(),
            'top_flight_revenue_chart': AnalyticsAdmin.generate_top_flight_revenue_chart(),
            'user_ticket_frequency_chart': AnalyticsAdmin.generate_user_ticket_frequency_chart(),
        })


# 自定义挂载
from backend.admin_site import custom_admin_site

analytics_admin = AnalyticsAdmin()
original_get_urls = custom_admin_site.get_urls


def custom_get_urls():
    return analytics_admin.get_custom_urls() + original_get_urls()


custom_admin_site.get_urls = custom_get_urls
