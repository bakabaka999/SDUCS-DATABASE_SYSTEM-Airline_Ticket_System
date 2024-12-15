from datetime import datetime
from django.contrib import admin

from backend.admin_site import custom_admin_site
from .models import Order, Plane, City, Airport, Flight, Ticket


@admin.register(Plane, site=custom_admin_site)
class PlaneAdmin(admin.ModelAdmin):
    list_display = ('plane_id', 'model', 'first_class_seats', 'business_seats', 'economy_seats')
    search_fields = ('plane_id', 'model')
    ordering = ('plane_id',)


@admin.register(City, site=custom_admin_site)
class CityAdmin(admin.ModelAdmin):
    list_display = ('city_name', 'province', 'city_code', 'pinyin')
    search_fields = ('city_name', 'province', 'city_code')
    ordering = ('city_name',)


@admin.register(Airport, site=custom_admin_site)
class AirportAdmin(admin.ModelAdmin):
    list_display = ('airport_name', 'airport_code', 'airport_code_3', 'city')
    list_filter = ('city',)
    search_fields = ('airport_name', 'airport_code', 'city__city_name')
    ordering = ('airport_name',)


@admin.register(Flight, site=custom_admin_site)
class FlightAdmin(admin.ModelAdmin):
    list_display = ('flight_id', 'departure_airport', 'arrival_airport', 'departure_time', 'arrival_time',
                    'remaining_first_class_seats', 'remaining_business_seats', 'remaining_economy_seats')
    list_filter = ('departure_airport', 'arrival_airport', 'departure_time', 'arrival_time')
    search_fields = ('flight_id', 'departure_airport__airport_name', 'arrival_airport__airport_name')
    ordering = ('departure_time',)
    actions = ['adjust_seat_availability']

    def adjust_seat_availability(self, request, queryset):
        for flight in queryset:
            flight.remaining_economy_seats += 5  # 示例：批量增加经济舱座位
            flight.save()
        self.message_user(request, "已成功调整航班座位数量！")

    adjust_seat_availability.short_description = "批量调整座位数量"


@admin.register(Ticket, site=custom_admin_site)
class TicketAdmin(admin.ModelAdmin):
    list_display = ('ticket_id', 'flight', 'seat_type', 'price', 'baggage_allowance')
    list_filter = ('seat_type', 'price')
    search_fields = ('flight__flight_id', 'seat_type')
    ordering = ('flight', 'seat_type')


@admin.register(Order, site=custom_admin_site)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_id', 'passenger', 'ticket', 'status', 'total_price', 'purchase_time', 'refund_amount',
        'refund_time')  # 展示字段
    list_filter = ('status', 'purchase_time')  # 筛选条件
    search_fields = ('order_id', 'passenger__name', 'ticket__ticket_type')  # 搜索字段
    actions = ['cancel_orders', 'mark_as_refunded']  # 自定义操作

    # 自定义操作：取消订单
    @admin.action(description='取消选中的订单')
    def cancel_orders(self, request, queryset):
        for order in queryset:
            try:
                order.cancel_order()
                self.message_user(request, f"订单 {order.order_id} 已成功取消。")
            except ValueError as e:
                self.message_user(request, f"订单 {order.order_id} 无法取消：{str(e)}", level='error')

    # 自定义操作：标记为已退款
    @admin.action(description='标记选中的订单为已退款')
    def mark_as_refunded(self, request, queryset):
        for order in queryset:
            if order.status == 'canceled':
                order.status = 'refunded'
                order.refund_time = datetime.now()
                order.save()
                self.message_user(request, f"订单 {order.order_id} 已标记为退款。")
            else:
                self.message_user(request, f"订单 {order.order_id} 无法标记为退款，当前状态：{order.status}",
                                  level='error')
