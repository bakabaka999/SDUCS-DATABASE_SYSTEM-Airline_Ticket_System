from django.urls import path
from .views import CityView, SearchFlightView, FlightTicketInfoView, PurchaseTicketView, ConfirmOrderView, \
    UserOrdersView, OrderDetailView, CancelOrderView, MinimumTicketPriceView

urlpatterns = [
    # 搜索城市
    path('city/', CityView.as_view(), name='city_list'),

    # 按城市搜索航班
    path('search/', SearchFlightView.as_view(), name='flight_search'),

    # 获取航班最低成人票票价
    path('ticket/min_price/<int:flight_id>/', MinimumTicketPriceView.as_view(), name='min_ticket_price'),

    # 获取某一航班的所有机票信息
    path('ticket/<int:flight_id>/', FlightTicketInfoView.as_view(), name='flight_detail'),

    # 创建订单
    path('order/purchase/', PurchaseTicketView.as_view(), name='flight_buy'),

    # 确认订单
    path('order/confirm/<int:order_id>/', ConfirmOrderView.as_view(), name='flight_confirm'),

    # 获取用户所有订单的简单信息
    path('order/list/', UserOrdersView.as_view(), name='flight_order_list'),

    # 获取用户某一订单的详细信息
    path('order/detail/<int:order_id>/', OrderDetailView.as_view(), name='flight_order_detail'),

    # 取消订单并申请退款
    path('order/cancel/<int:order_id>/', CancelOrderView.as_view(), name='flight_order_cancel'),
]
