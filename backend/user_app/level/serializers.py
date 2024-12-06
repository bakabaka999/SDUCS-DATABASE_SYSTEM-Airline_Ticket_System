from rest_framework import serializers
from .models import Level  # 引入 Level 模型

class LevelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Level
        fields = '__all__'  # 或者列出你想要的字段
