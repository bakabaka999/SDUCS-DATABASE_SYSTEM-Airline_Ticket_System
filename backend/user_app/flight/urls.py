from django.urls import path
from .views import CityView, SearchFlightView, FlightTicketInfoView, PurchaseTicketView

urlpatterns = [
    # 搜索城市
    path('city/', CityView.as_view(), name='city_list'),

    # 按城市搜索航班
    path('search/', SearchFlightView.as_view(), name='flight_search'),

    # 获取某一航班的所有机票信息
    path('ticket/<int:flight_id>/', FlightTicketInfoView.as_view(), name='flight_detail'),

    # 购买机票
    path('buy/', PurchaseTicketView.as_view(), name='flight_buy'),

    # 获取订单信息
]
