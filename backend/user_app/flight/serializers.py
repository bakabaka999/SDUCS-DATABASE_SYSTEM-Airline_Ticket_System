from rest_framework import serializers
from .models import Flight, Plane, Ticket, Airport, Order


class PlaneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Plane
        fields = '__all__'


class AirportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Airport
        fields = '__all__'


class FlightSerializer(serializers.ModelSerializer):
    plane = PlaneSerializer()
    departure_airport = AirportSerializer()
    arrival_airport = AirportSerializer()

    class Meta:
        model = Flight
        fields = '__all__'


class TicketSerializer(serializers.ModelSerializer):
    flight = FlightSerializer()

    class Meta:
        model = Ticket
        fields = '__all__'


class SimpleOrderSerializer(serializers.ModelSerializer):
    passenger_name = serializers.CharField(source='passenger.name')  # 乘机人名字
    flight_info = serializers.SerializerMethodField()  # 航班简单信息

    class Meta:
        model = Order
        fields = ['order_id', 'passenger_name', 'status', 'flight_info']

    @staticmethod
    def get_flight_info(obj):
        flight = obj.ticket.flight
        return {
            'flight_id': flight.flight_id,
            'departure_airport': flight.departure_airport.airport_name,
            'arrival_airport': flight.arrival_airport.airport_name,
            'departure_time': flight.departure_time,
            'arrival_time': flight.arrival_time,
        }


class OrderSerializer(serializers.ModelSerializer):
    ticket = serializers.SerializerMethodField()
    passenger = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['order_id', 'passenger', 'ticket', 'purchase_time', 'status', 'total_price']

    @staticmethod
    def get_ticket(obj):
        ticket = obj.ticket
        flight = ticket.flight
        return {
            'ticket_id': ticket.ticket_id,
            'price': ticket.price,
            'seat_type': ticket.seat_type,
            'ticket_type': ticket.ticket_type,
            'baggage_allowance': ticket.baggage_allowance,
            'flight': {
                'flight_id': flight.flight_id,
                'departure_time': flight.departure_time,
                'arrival_time': flight.arrival_time,
                'departure_airport': flight.departure_airport.airport_name,
                'arrival_airport': flight.arrival_airport.airport_name,
            }
        }

    @staticmethod
    def get_passenger(obj):
        passenger = obj.passenger
        return {
            'name': passenger.name,
            'gender': 'Male' if passenger.gender else 'Female',
            'phone_number': passenger.phone_number,
            'email': passenger.email,
        }
