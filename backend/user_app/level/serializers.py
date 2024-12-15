from rest_framework import serializers
from .models import Level, Promotion  # 引入 Level 模型


class LevelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Level
        fields = '__all__'  # 或者列出你想要的字段


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ['name', 'description', 'start_date', 'end_date']

