from django.urls import path
from django.template.response import TemplateResponse
from django.db.models import Count, Sum
from django.http import HttpResponse
import pandas as pd
import io
import base64
from user_app.account.models import User
from user_app.flight.models import Flight, Order

import matplotlib

matplotlib.use('Agg')  # 必须在导入 pyplot 之前设置后端

import matplotlib.pyplot as plt

from matplotlib import rcParams

rcParams['font.sans-serif'] = ['SimHei']  # 设置字体为黑体
rcParams['axes.unicode_minus'] = False  # 解决负号显示问题


class AnalyticsAdmin:
    """扩展自定义管理站点的统计功能"""

    def get_custom_urls(self):
        """将统计功能挂载到自定义管理站点的 URL"""
        return [
            path('analytics/', self.statistics_view, name='custom_analytics'),
        ]

    @staticmethod
    def generate_order_trend_chart():
        """生成订单趋势图"""
        orders_by_date = (
            Order.objects.filter(status='confirmed')
            .extra({'day': "date(purchase_time)"})
            .values('day')
            .annotate(order_count=Count('order_id'))
            .order_by('day')
        )
        dates = [order['day'] for order in orders_by_date]
        counts = [order['order_count'] for order in orders_by_date]

        # 设置中文字体以解决中文显示问题

        plt.figure(figsize=(8, 4))
        plt.plot(dates, counts, marker='o', color='blue', label='订单数')
        plt.title("订单趋势图")
        plt.xlabel("日期")
        plt.ylabel("订单数")
        plt.xticks(rotation=45)
        plt.legend()
        plt.tight_layout()

        return AnalyticsAdmin._convert_to_base64()

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
        dates = [revenue['day'] for revenue in revenue_by_date]
        revenues = [revenue['total_revenue'] or 0 for revenue in revenue_by_date]

        # 设置中文字体以解决中文显示问题
        from matplotlib import rcParams
        rcParams['font.sans-serif'] = ['SimHei']  # 设置字体为黑体
        rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

        plt.figure(figsize=(8, 4))
        plt.bar(dates, revenues, color='green', label='每日收入')
        plt.title("每日收入趋势")
        plt.xlabel("日期")
        plt.ylabel("收入 (￥)")
        plt.xticks(rotation=45)
        plt.legend()
        plt.tight_layout()

        return AnalyticsAdmin._convert_to_base64()

    # @staticmethod
    # def generate_user_growth_chart():
    #     """生成用户增长趋势图"""
    #     user_growth_by_date = (
    #         User.objects.extra({'day': "date(date_joined)"})
    #         .values('day')
    #         .annotate(new_users=Count('id'))
    #         .order_by('day')
    #     )
    #     dates = [growth['day'] for growth in user_growth_by_date]
    #     new_users = [growth['new_users'] for growth in user_growth_by_date]
    #
    #     plt.figure(figsize=(8, 4))
    #     plt.plot(dates, new_users, marker='o', color='orange', label='新增用户')
    #     plt.title("用户增长趋势")
    #     plt.xlabel("日期")
    #     plt.ylabel("新增用户数")
    #     plt.xticks(rotation=45)
    #     plt.legend()
    #     plt.tight_layout()
    #
    #     return AnalyticsAdmin._convert_to_base64()

    @staticmethod
    def generate_order_status_chart():
        """生成订单状态分布图"""
        status_counts = (
            Order.objects.values('status')
            .annotate(count=Count('order_id'))
        )
        labels = [status['status'] for status in status_counts]
        sizes = [status['count'] for status in status_counts]

        # 设置中文字体以解决中文显示问题
        from matplotlib import rcParams
        rcParams['font.sans-serif'] = ['SimHei']  # 设置字体为黑体
        rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

        plt.figure(figsize=(6, 6))
        plt.pie(sizes, labels=labels, autopct='%1.1f%%', startangle=140)
        plt.title("订单状态分布")
        plt.tight_layout()

        return AnalyticsAdmin._convert_to_base64()

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

    @staticmethod
    def statistics_view(request):
        """统计页面视图"""
        # 统计数据
        stats = {
            'total_users': User.objects.count(),
            'total_orders': Order.objects.count(),
            'total_sales': Order.objects.filter(status='confirmed').aggregate(Sum('total_price'))[
                               'total_price__sum'] or 0,
            'total_flights': Flight.objects.count(),
        }

        # 图表
        order_trend_chart = AnalyticsAdmin.generate_order_trend_chart()
        revenue_trend_chart = AnalyticsAdmin.generate_revenue_trend_chart()
        # user_growth_chart = AnalyticsAdmin.generate_user_growth_chart()
        order_status_chart = AnalyticsAdmin.generate_order_status_chart()

        # 渲染模板
        return TemplateResponse(request, "admin/analytics.html", {
            'stats': stats,
            'order_trend_chart': order_trend_chart,
            'revenue_trend_chart': revenue_trend_chart,
            # 'user_growth_chart': user_growth_chart,
            'order_status_chart': order_status_chart,
        })

    @staticmethod
    def export_report(request):
        """导出数据报表为 Excel"""
        # 获取订单数据
        orders = Order.objects.all().values('order_id', 'passenger__name', 'ticket__price', 'status', 'purchase_time')
        df = pd.DataFrame(orders)

        # 重命名列为中文
        df.rename(columns={
            'order_id': '订单号',
            'passenger__name': '乘机人',
            'ticket__price': '票价',
            'status': '订单状态',
            'purchase_time': '购买时间',
        }, inplace=True)

        # 将 DataFrame 写入 Excel 文件
        response = HttpResponse(content_type='application/vnd.ms-excel')
        response['Content-Disposition'] = 'attachment; filename="订单统计报表.xlsx"'
        with pd.ExcelWriter(response, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='订单统计')
        return response


# 挂靠到自定义管理站点
from backend.admin_site import custom_admin_site

analytics_admin = AnalyticsAdmin()
original_get_urls = custom_admin_site.get_urls


def custom_get_urls():
    custom_urls = analytics_admin.get_custom_urls()
    return custom_urls + original_get_urls()


custom_admin_site.get_urls = custom_get_urls
