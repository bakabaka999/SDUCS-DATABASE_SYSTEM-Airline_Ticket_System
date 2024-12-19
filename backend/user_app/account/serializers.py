from rest_framework import serializers
from .models import User, Passenger, Invoice


class UserSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField()  # 声明为 SerializerMethodField

    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'phone_number', 'accumulated_miles', 'ticked_count', 'avatar_url']

    def get_avatar_url(self, obj):
        """
        获取头像的完整 URL
        """
        request = self.context.get('request')  # 获取当前请求
        if obj.avatar and hasattr(obj.avatar, 'url'):  # 确保头像存在并且有 URL 属性
            if request:
                return request.build_absolute_uri(obj.avatar.url)  # 返回完整的头像 URL
            return obj.avatar.url  # 如果没有 request，返回相对路径
        return None  # 如果头像不存在，返回 None


class PassengerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Passenger
        fields = ['id', 'name', 'gender', 'phone_number', 'email', 'person_type', 'birth_date']


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = ['type', 'name', 'identification_number', 'company_address', 'phone_number', 'bank_name', 'bank_account']
