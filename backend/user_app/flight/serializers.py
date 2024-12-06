from rest_framework import serializers
from .models import Flight, Plane, Ticket, Airport


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

