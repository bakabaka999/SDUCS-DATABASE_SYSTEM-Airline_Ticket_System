from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from .models import Level, User
from .serializers import LevelSerializer


@api_view(['GET'])
def get_user_level(request):
    # 获取当前用户对象
    user = request.user

    # 显式获取 user 实例，避免 SimpleLazyObject 问题
    try:
        user = User.objects.get(id=user.id)
    except ObjectDoesNotExist:
        return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

    # 获取用户的里程和购票次数
    user_miles = user.accumulated_miles
    user_tickets = user.ticked_count

    # 查询符合条件的等级
    try:
        levels = Level.objects.all().order_by('level')

        # 找到符合条件的等级
        user_level = None
        for level in levels:
            if user_miles >= level.require_miles or user_tickets >= level.require_tickets:
                user_level = level
            else:
                break

        if user_level is None:
            return Response({"detail": "用户等级未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 使用 LevelSerializer 序列化 Level 实例
        level_data = LevelSerializer(user_level).data

        return Response({"level": level_data}, status=status.HTTP_200_OK)

    except Level.DoesNotExist:
        return Response({"detail": "等级信息未找到"}, status=status.HTTP_404_NOT_FOUND)




    # 获取与用户等级相关联的 Level 实例
    level_instance = user_level.level

    # 使用 LevelSerializer 序列化 Level 实例
    level_data = LevelSerializer(level_instance).data

    return Response({'level': level_data})

