from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Airport, Flight, City, Ticket, Order  # 假设City模型已经包含city_name和pinyin字段
from django.db.models import Q  # 用于复杂查询

from ..account.models import Passenger


# 考虑分页优化
# Create your views here.
class CityView(APIView):
    """
    城市查询接口。支持按拼音首字母排序的所有城市查询和模糊查询。
    """

    # 查询所有城市并按拼音首字母排序
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
        city_list = [{"city_name": city.city_name, "pinyin": city.pinyin} for city in cities]
        return Response(city_list, status=status.HTTP_200_OK)


class SearchFlightView(APIView):
    """
    根据城市外码查询航班。
    输入：起始城市外码（departure_city_code）、终点城市外码（arrival_city_code）
    输出：符合条件的所有航班信息
    """

    def get(self, request):
        # 获取查询参数
        departure_city_code = request.query_params.get('departure_city_code')
        arrival_city_code = request.query_params.get('arrival_city_code')

        # 校验参数
        if not departure_city_code or not arrival_city_code:
            return Response({"error": "Please provide both departure and arrival city codes."},
                            status=status.HTTP_400_BAD_REQUEST)

        # 查找起始城市和终点城市
        try:
            departure_airport = Airport.objects.get(airport_code=departure_city_code)
            arrival_airport = Airport.objects.get(airport_code=arrival_city_code)
        except Airport.DoesNotExist:
            return Response({"error": "One or both of the provided city codes are invalid."},
                            status=status.HTTP_404_NOT_FOUND)

        # 查找航班
        flights = Flight.objects.filter(departure_airport=departure_airport, arrival_airport=arrival_airport)

        # 如果没有找到航班
        if not flights:
            return Response({"message": "No flights found for the provided city codes."},
                            status=status.HTTP_404_NOT_FOUND)

        # 序列化航班信息
        flight_data = []
        for flight in flights:
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
    输入：用户ID、乘机人ID、机票ID
    输出：订单信息，购买成功后返回订单详细信息，失败返回错误信息
    """

    def post(self, request):
        user_id = request.data.get("user_id")
        passenger_id = request.data.get("passenger_id")
        ticket_id = request.data.get("ticket_id")

        if not user_id or not passenger_id or not ticket_id:
            return Response({"error": "Please provide user_id, passenger_id, and ticket_id."},
                             status=status.HTTP_400_BAD_REQUEST)

        try:
            passenger = Passenger.objects.get(id=passenger_id)
            ticket = Ticket.objects.get(ticket_id=ticket_id)

            # 确保乘客类型与机票类型匹配
            if passenger.person_type != ticket.ticket_type:
                return Response({
                    "error": f"Passenger type '{passenger.person_type}' does not match ticket type '{ticket.ticket_type}'."},
                    status=status.HTTP_400_BAD_REQUEST)

            # 获取航班信息
            flight = ticket.flight

            # 确保有足够座位
            if ticket.seat_type == 'economy' and flight.remaining_economy_seats <= 0:
                return Response({"error": "No available economy seats for this flight."},
                                 status=status.HTTP_400_BAD_REQUEST)
            elif ticket.seat_type == 'business' and flight.remaining_business_seats <= 0:
                return Response({"error": "No available business class seats for this flight."},
                                 status=status.HTTP_400_BAD_REQUEST)
            elif ticket.seat_type == 'first_class' and flight.remaining_first_class_seats <= 0:
                return Response({"error": "No available first class seats for this flight."},
                                 status=status.HTTP_400_BAD_REQUEST)

            # 创建订单
            with transaction.atomic():
                order = Order.objects.create(
                    passenger=passenger,
                    ticket=ticket,
                    total_price=ticket.price,
                    status='confirmed'
                )

                # 根据座位类型更新剩余座位
                if ticket.seat_type == 'economy':
                    flight.remaining_economy_seats -= 1
                elif ticket.seat_type == 'business':
                    flight.remaining_business_seats -= 1
                elif ticket.seat_type == 'first_class':
                    flight.remaining_first_class_seats -= 1

                flight.save()

            return Response({
                "message": "Ticket purchased successfully!",
                "order_id": order.order_id,
                "ticket_type": ticket.ticket_type,
                "seat_type": ticket.seat_type,
                "total_price": order.total_price,
                "purchase_time": order.purchase_time
            }, status=status.HTTP_201_CREATED)

        except Passenger.DoesNotExist:
            return Response({"error": "Passenger not found."}, status=status.HTTP_404_NOT_FOUND)
        except Ticket.DoesNotExist:
            return Response({"error": "Ticket not found."}, status=status.HTTP_404_NOT_FOUND)
        except Flight.DoesNotExist:
            return Response({"error": "Flight not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
