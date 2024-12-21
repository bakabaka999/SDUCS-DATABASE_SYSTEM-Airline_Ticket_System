from datetime import datetime, timedelta
from django.db import transaction
from django.utils.timezone import make_aware
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Airport, Flight, City, Ticket, Order  # 假设City模型已经包含city_name和pinyin字段
from django.db.models import Q  # 用于复杂查询

from .serializers import SimpleOrderSerializer, OrderSerializer
from ..account.models import Passenger, UserPassengerRelation, User


# 考虑分页优化
# Create your views here.
class CityView(APIView):
    """
    城市查询接口。支持按拼音首字母排序的所有城市查询和模糊查询。
    """

    @staticmethod
    def get(request):
        query = request.query_params.get('query', '')  # 获取查询参数，默认为空字符串

        if query:  # 如果有查询条件，则进行模糊查询
            cities = City.objects.filter(
                Q(city_name__icontains=query) |  # 模糊查询城市名
                Q(pinyin__icontains=query)  # 模糊查询拼音首字母
            ).order_by('pinyin')  # 按拼音首字母排序
        else:  # 如果没有查询条件，则返回所有城市，按拼音首字母排序
            cities = City.objects.all().order_by('pinyin')

        # 将城市数据序列化并返回
        city_list = [
            {
                "city_name": city.city_name,  # 城市名称
                "city_code": city.city_code,  # 城市编号
                "pinyin": city.pinyin,  # 城市拼音
            }
            for city in cities
        ]
        return Response(city_list, status=status.HTTP_200_OK)


class SearchFlightView(APIView):
    """
    根据城市外码查询航班。
    输入：起始城市外码（departure_city_code）、终点城市外码（arrival_city_code）、起飞日期（departure_date）
    输出：符合条件的所有航班信息
    """

    @staticmethod
    def get(request):
        # 获取查询参数
        departure_city_code = request.query_params.get('departure_city_code')
        arrival_city_code = request.query_params.get('arrival_city_code')
        departure_date = request.query_params.get('departure_date')  # 新增参数：起飞日期

        # 校验参数
        if not departure_city_code or not arrival_city_code:
            return Response(
                {"error": "Please provide both departure and arrival city codes."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # 查找起始城市和终点城市的所有机场
            departure_airports = Airport.objects.filter(city__city_code=departure_city_code)
            arrival_airports = Airport.objects.filter(city__city_code=arrival_city_code)

            if not departure_airports.exists() or not arrival_airports.exists():
                return Response(
                    {"error": "No airports found for one or both provided city codes."},
                    status=status.HTTP_404_NOT_FOUND
                )

            # 查询这些机场之间的航班
            flight_query = Flight.objects.filter(
                departure_airport__in=departure_airports,
                arrival_airport__in=arrival_airports,
            )

            # 如果提供了起飞日期，则进一步筛选
            if departure_date:
                try:
                    # 转换日期字符串为 naive datetime（不带时区）
                    start_time = datetime.strptime(departure_date, "%Y-%m-%d")
                    end_time = start_time + timedelta(days=1)

                    # 直接过滤时间范围，避免 __date 失效
                    flight_query = flight_query.filter(
                        departure_time__gte=start_time,
                        departure_time__lt=end_time
                    )
                except ValueError:
                    return Response(
                        {"error": "Invalid date format. Please use YYYY-MM-DD."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

            print(flight_query)

            # 如果没有找到航班
            if not flight_query.exists():
                return Response(
                    {"message": "No flights found for the provided city codes and date."},
                    status=status.HTTP_404_NOT_FOUND
                )

            # 序列化航班信息
            flight_data = []
            for flight in flight_query:
                flight_data.append({
                    "flight_id": flight.flight_id,
                    "departure_time": flight.departure_time,
                    "arrival_time": flight.arrival_time,
                    "departure_airport": flight.departure_airport.airport_name,
                    "arrival_airport": flight.arrival_airport.airport_name,
                    "remaining_first_class_seats": flight.remaining_first_class_seats,
                    "remaining_business_seats": flight.remaining_business_seats,
                    "remaining_economy_seats": flight.remaining_economy_seats,
                    "plane_model": flight.plane.model,
                })

            return Response(flight_data, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {"error": f"An error occurred: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class MinimumTicketPriceView(APIView):
    """
    获取某航班的最低成人票票价及座位类型接口
    输入：航班ID
    输出：最低成人票票价及座位类型
    """

    @staticmethod
    def get(request, flight_id):
        try:
            # 获取航班的所有成人票
            tickets = Ticket.objects.filter(flight_id=flight_id, ticket_type='adult')

            # 如果没有找到成人票，返回404
            if not tickets.exists():
                return Response(
                    {"message": "No adult tickets found for the provided flight ID."},
                    status=status.HTTP_404_NOT_FOUND,
                )

            # 获取最低价格的机票
            min_ticket = tickets.order_by('price').first()

            return Response(
                {
                    "flight_id": flight_id,
                    "min_price": min_ticket.price,
                    "seat_type": min_ticket.seat_type,  # 返回座位类型
                },
                status=status.HTTP_200_OK,
            )
        except Exception as e:
            return Response(
                {"message": f"An error occurred: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class FlightTicketInfoView(APIView):
    """
    展示某一航班的所有机票信息。
    输入：航班ID
    输出：该航班所有机票的详细信息（包括票价、座位类型、剩余座位等）
    """

    def get(self, request, flight_id):
        try:
            # 获取航班对象
            flight = Flight.objects.get(flight_id=flight_id)

            # 获取该航班的所有机票
            tickets = Ticket.objects.filter(flight=flight)

            # 如果没有机票
            if not tickets:
                return Response({"message": "No tickets available for this flight."}, status=status.HTTP_404_NOT_FOUND)

            # 构建机票数据
            ticket_data = []
            for ticket in tickets:
                ticket_data.append({
                    "ticket_id": ticket.ticket_id,
                    "ticket_type": ticket.ticket_type,
                    "seat_type": ticket.seat_type,  # 返回座位类型
                    "price": ticket.price,
                    "baggage_allowance": ticket.baggage_allowance,
                    "remaining_seats": self.get_remaining_seats(ticket, flight),
                })

            # 返回航班的所有机票信息
            return Response(ticket_data, status=status.HTTP_200_OK)

        except Flight.DoesNotExist:
            return Response({"error": "Flight not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @staticmethod
    def get_remaining_seats(ticket, flight):
        """
        根据机票类型和座位类型返回剩余座位数。
        """
        if ticket.seat_type == 'economy':
            return flight.remaining_economy_seats
        elif ticket.seat_type == 'business':
            return flight.remaining_business_seats
        elif ticket.seat_type == 'first_class':
            return flight.remaining_first_class_seats
        return 0


class PurchaseTicketView(APIView):
    """
    用户为其乘机人购买航班机票。
    """

    @staticmethod
    def post(request):
        passenger_id = request.data.get("passenger_id")
        ticket_id = request.data.get("ticket_id")

        if not passenger_id or not ticket_id:
            return Response(
                {"error": "Missing passenger_id or ticket_id."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            with transaction.atomic():
                # 获取乘机人和机票信息
                passenger = Passenger.objects.select_for_update().get(id=passenger_id)
                ticket = Ticket.objects.select_related("flight").get(ticket_id=ticket_id)

                order = Order.objects.filter(ticket=ticket, passenger=passenger, status="confirmed").first()

                if order:
                    return Response(
                        {"error": "You have already purchased this ticket."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                # 验证乘机人类型与机票类型匹配
                if ticket.ticket_type == 'adult':
                    pass
                elif passenger.person_type != ticket.ticket_type:
                    return Response(
                        {
                            "error": f"Passenger type '{passenger.person_type}' does not match ticket type '{ticket.ticket_type}'."
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                flight = ticket.flight

                # 锁定航班记录
                flight = Flight.objects.select_for_update().get(flight_id=flight.flight_id)

                # 确保有足够座位
                if ticket.seat_type == "economy" and flight.remaining_economy_seats <= 0:
                    return Response(
                        {"error": "No available economy seats for this flight."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                elif ticket.seat_type == "business" and flight.remaining_business_seats <= 0:
                    return Response(
                        {"error": "No available business class seats for this flight."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                elif ticket.seat_type == "first_class" and flight.remaining_first_class_seats <= 0:
                    return Response(
                        {"error": "No available first class seats for this flight."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                # 创建订单
                order = Order.objects.create(
                    passenger=passenger,
                    ticket=ticket,
                    total_price=ticket.price,
                    status="pending",
                )

                # 更新航班座位
                if ticket.seat_type == "economy":
                    flight.remaining_economy_seats -= 1
                elif ticket.seat_type == "business":
                    flight.remaining_business_seats -= 1
                elif ticket.seat_type == "first_class":
                    flight.remaining_first_class_seats -= 1

                flight.save()

            return Response(
                {
                    "message": "Ticket purchased successfully.",
                    "order_id": order.order_id,
                    "ticket_type": ticket.ticket_type,
                    "status": order.status,
                    "seat_type": ticket.seat_type,
                    "total_price": order.total_price,
                    "purchase_time": order.purchase_time,
                },
                status=status.HTTP_201_CREATED,
            )

        except Passenger.DoesNotExist:
            print("Passenger not found.")
            return Response({"error": "Passenger not found."}, status=status.HTTP_404_NOT_FOUND)
        except Ticket.DoesNotExist:
            print("Ticket not found.")
            return Response({"error": "Ticket not found."}, status=status.HTTP_404_NOT_FOUND)
        except Flight.DoesNotExist:
            print("Flight not found.")
            return Response({"error": "Flight not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": f"System error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ConfirmOrderView(APIView):
    """
    支付订单视图，确认订单并扣减座位。
    """
    permission_classes = [IsAuthenticated]

    @staticmethod
    def post(request, order_id):
        try:
            # 获取订单
            order = Order.objects.select_related("ticket__flight", "passenger").get(order_id=order_id)

            auth_user = request.user
            user = User.objects.get(name=auth_user.username)
            # 检查当前用户是否与该订单的乘机人有关联
            if not UserPassengerRelation.objects.filter(user_id=user.id, passenger=order.passenger).exists():
                return Response(
                    {"error": "You do not have permission to confirm this order."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            # 检查订单状态
            if order.status != "pending":
                return Response({"error": "Only pending orders can be confirmed."}, status=status.HTTP_400_BAD_REQUEST)

            flight = order.ticket.flight

            # 锁定航班记录
            with transaction.atomic():
                flight = Flight.objects.select_for_update().get(flight_id=flight.flight_id)

                # 更新订单状态和航班座位
                order.status = "confirmed"  # 更新订单状态为已支付
                order.save()

                flight.save()

            # 当付款成功时，计算用户累计里程数与购票数
            user.accumulated_miles += flight.distance
            user.ticked_count += 1
            user.save()

            return Response(
                {"message": "Order confirmed successfully.", "order_id": order.order_id, "status": order.status},
                status=status.HTTP_200_OK,
            )

        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": f"System error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UserOrdersView(APIView):
    """
    获取用户的所有订单的简单信息
    - 可根据订单状态筛选：pending, confirmed, canceled, refunded
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        status_filter = request.query_params.get('status')  # 获取订单状态筛选条件

        auth_user = request.user
        user = User.objects.get(name=auth_user.username)

        passenger_ids = UserPassengerRelation.objects.filter(user_id=user.id).values_list('passenger_id',
                                                                                          flat=True)

        orders = Order.objects.filter(passenger_id__in=passenger_ids)

        if status_filter:
            orders = orders.filter(status=status_filter)

        orders = orders.order_by('-purchase_time')  # 按时间降序排列
        serializer = SimpleOrderSerializer(orders, many=True)
        return Response(serializer.data, status=200)


class OrderDetailView(APIView):
    """
    获取某一订单的详细信息
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, order_id):
        try:
            # 获取订单
            order = Order.objects.select_related("ticket__flight", "passenger").get(order_id=order_id)

            auth_user = request.user
            user = User.objects.get(name=auth_user.username)
            # 检查当前用户是否与该订单的乘机人有关联
            if not UserPassengerRelation.objects.filter(user_id=user.id, passenger=order.passenger).exists():
                return Response(
                    {"error": "You do not have permission to confirm this order."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            serializer = OrderSerializer(order)
            return Response(serializer.data, status=200)
        except Order.DoesNotExist:
            return Response({"error": "Order not found or access denied."}, status=404)


class CancelOrderView(APIView):
    """
    取消订单视图。
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, order_id):
        try:
            # 开启事务并锁定订单
            with transaction.atomic():
                # 获取订单并使用 SELECT FOR UPDATE 锁定
                order = Order.objects.select_related("ticket__flight", "passenger").select_for_update().get(
                    order_id=order_id
                )

                auth_user = request.user
                user = User.objects.get(name=auth_user.username)

                # 检查当前用户是否与该订单的乘机人有关联
                if not UserPassengerRelation.objects.filter(user_id=user.id,
                                                            passenger=order.passenger).exists():
                    return Response(
                        {"error": "You do not have permission to cancel this order."},
                        status=status.HTTP_403_FORBIDDEN,
                    )

                # 判断订单状态
                if order.status == 'confirmed' or order.status == 'pending':
                    # 已支付订单逻辑：调用模型方法取消订单并计算退款
                    if not order.can_cancel():
                        return Response(
                            {"error": "Order cannot be canceled or already refunded."},
                            status=status.HTTP_400_BAD_REQUEST,
                        )
                    order.cancel_order()

                else:
                    # 订单已取消或已退款
                    return Response(
                        {"error": "Order is already canceled or refunded."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

            return Response(
                {
                    "message": "Order canceled successfully.",
                    "order_id": order.order_id,
                    "refund_amount": order.refund_amount,
                    "refund_time": order.refund_time,
                },
                status=status.HTTP_200_OK,
            )

        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": f"System error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
