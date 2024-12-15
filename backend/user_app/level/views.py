from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from .models import Level, User, Promotion
from .serializers import LevelSerializer, PromotionSerializer


@api_view(['GET'])
def get_user_level(request):
    user = request.user

    # 获取用户信息
    try:
        user = User.objects.get(name=user.username)
    except ObjectDoesNotExist:
        return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

    user_miles = user.accumulated_miles
    user_tickets = user.ticked_count

    try:
        # 查询所有等级，找到当前用户满足的最高等级
        levels = Level.objects.all().order_by('level')
        user_level = None

        for level in levels:
            if user_miles >= level.require_miles or user_tickets >= level.require_tickets:
                user_level = level
            else:
                break

        if user_level is None:
            return Response({"detail": "用户等级未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 序列化等级数据
        level_data = LevelSerializer(user_level).data

        return Response({
            "level": level_data,
            "level_name": level.__str__(),
            "user_miles": user_miles,
            "user_tickets": user_tickets
        }, status=status.HTTP_200_OK)

    except Level.DoesNotExist:
        return Response({"detail": "等级信息未找到"}, status=status.HTTP_404_NOT_FOUND)



@api_view(['GET'])
def get_user_promotions(request):
    """
    获取与用户等级相关联的活动信息
    """
    # 获取当前用户对象
    user = request.user

    # 显式获取 user 实例，避免 SimpleLazyObject 问题
    try:
        user = User.objects.get(name=user.username)
    except ObjectDoesNotExist:
        return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

    # 获取用户的里程和购票次数
    user_miles = user.accumulated_miles
    user_tickets = user.ticked_count

    # 查询符合条件的等级
    try:
        levels = Level.objects.all().order_by('level')

        # 找到符合条件的最高等级
        user_level = None
        for level in levels:
            if user_miles >= level.require_miles or user_tickets >= level.require_tickets:
                user_level = level
            else:
                break

        if user_level is None:
            return Response({"detail": "用户等级未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 查询与该等级关联的活动信息
        promotions = Promotion.objects.filter(level=user_level)

        # 序列化活动信息
        promotion_data = PromotionSerializer(promotions, many=True).data

        return Response({"promotions": promotion_data}, status=status.HTTP_200_OK)

    except Level.DoesNotExist:
        return Response({"detail": "等级信息未找到"}, status=status.HTTP_404_NOT_FOUND)
    except Promotion.DoesNotExist:
        return Response({"detail": "没有找到相关活动信息"}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
def get_next_level(request):
    user = request.user

    try:
        user = User.objects.get(name=user.username)
    except ObjectDoesNotExist:
        return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

    user_miles = user.accumulated_miles
    user_tickets = user.ticked_count

    try:
        # 查询所有等级，找出下一个未达到的等级
        levels = Level.objects.all().order_by('level')

        next_level = None
        for level in levels:
            if user_miles < level.require_miles and user_tickets < level.require_tickets:
                next_level = level
                break

        if next_level is None:
            return Response({"detail": "您已达到最高等级"}, status=status.HTTP_200_OK)

        next_level_data = {
            "level_name": dict(Level.LEVEL_CHOICES).get(next_level.level),
            "require_miles": next_level.require_miles - user_miles,
            "require_tickets": next_level.require_tickets - user_tickets,
        }

        return Response({"next_level": next_level_data}, status=status.HTTP_200_OK)

    except Level.DoesNotExist:
        return Response({"detail": "等级信息未找到"}, status=status.HTTP_404_NOT_FOUND)
