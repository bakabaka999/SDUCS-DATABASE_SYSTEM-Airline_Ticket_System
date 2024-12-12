from rest_framework import serializers
from .models import User, Passenger, Invoice


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'phone_number', 'accumulated_miles', 'ticked_count']


class PassengerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Passenger
        fields = ['id', 'name', 'gender', 'phone_number', 'email', 'person_type', 'birth_date']


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = ['type', 'name', 'identification_number', 'company_address', 'phone_number', 'bank_name', 'bank_account']
