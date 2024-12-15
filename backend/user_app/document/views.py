from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Document
from user_app.account.models import User, Passenger, UserPassengerRelation
from .serializers import DocumentSerializer
from django.core.exceptions import ObjectDoesNotExist


class DocumentView(APIView):
    """
    证件管理接口。用户可以通过POST请求添加证件信息，PUT请求更新证件信息，DELETE请求删除证件信息。
    """
    permission_classes = [IsAuthenticated]  # 只有认证通过的用户才能访问此接口

    @staticmethod
    def get(request, passenger_id):
        # 获取当前用户
        auth_user = request.user
        user = User.objects.get(name=auth_user.username)
        passenger = Passenger.objects.get(id=passenger_id)

        try:
            # 验证当前用户是否拥有此乘机人
            if not UserPassengerRelation.objects.filter(user=user.id, passenger=passenger.id).exists():
                return Response({"detail": "您没有权限查看此乘机人的证件信息"}, status=status.HTTP_403_FORBIDDEN)

            # 获取乘机人的所有证件
            documents = Document.objects.filter(passenger_id=passenger_id)
            serializer = DocumentSerializer(documents, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Passenger.DoesNotExist:
            return Response({"detail": "乘机人未找到"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @staticmethod
    def post(request):
        # 创建新的证件信息
        user = request.user
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 从请求中获取数据
        passenger_id = request.data.get('passenger_id')
        try:
            passenger = Passenger.objects.get(id=passenger_id)
        except Passenger.DoesNotExist:
            return Response({"detail": "乘客未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 确保乘客属于当前用户
        if not UserPassengerRelation.objects.filter(user=user, passenger=passenger).exists():
            return Response({"detail": "您没有权限为此乘客添加证件"}, status=status.HTTP_403_FORBIDDEN)

        # 创建证件
        serializer = DocumentSerializer(data=request.data)
        if serializer.is_valid():
            # 通过passenger关联用户添加证件
            serializer.save(passenger=passenger)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def put(request, document_id):
        # 更新证件信息
        try:
            document = Document.objects.get(document_id=document_id)
        except Document.DoesNotExist:
            return Response({"detail": "证件未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 验证当前用户是否有权修改此证件（通过证件关联的乘客检查）
        user = request.user
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        passenger = document.passenger
        try:
            passenger = Passenger.objects.get(id=passenger.id)
        except Passenger.DoesNotExist:
            return Response({"detail": "乘客未找到"}, status=status.HTTP_404_NOT_FOUND)

        if not UserPassengerRelation.objects.filter(user=user, passenger=passenger).exists():
            return Response({"detail": "您没有权限更新该证件"}, status=status.HTTP_403_FORBIDDEN)

        serializer = DocumentSerializer(document, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def delete(request, document_id):
        # 删除证件信息
        try:
            document = Document.objects.get(document_id=document_id)
        except Document.DoesNotExist:
            return Response({"detail": "证件未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 验证当前用户是否有权删除此证件（通过证件关联的乘客检查）
        user = request.user
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)
        passenger = document.passenger
        try:
            passenger = Passenger.objects.get(id=passenger.id)
        except Passenger.DoesNotExist:
            return Response({"detail": "乘客未找到"}, status=status.HTTP_404_NOT_FOUND)
        if not UserPassengerRelation.objects.filter(user=user, passenger=passenger).exists():
            return Response({"detail": "您没有权限删除该证件"}, status=status.HTTP_403_FORBIDDEN)

        document.delete()
        return Response({"detail": "证件已删除"}, status=status.HTTP_204_NO_CONTENT)


class PassengerDocumentView(APIView):
    """
    证件详情接口。用户可以通过GET请求获取某一位乘客的证件信息。
    """
    permission_classes = [IsAuthenticated]  # 只有认证通过的用户才能访问此接口

    @staticmethod
    def get(request, passenger_id):
        # 获取某一位乘客的证件信息
        try:
            passenger = Passenger.objects.get(id=passenger_id)
        except Passenger.DoesNotExist:
            return Response({"detail": "乘客未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 验证当前用户是否有权查看此乘客的证件信息
        user = request.user
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        if not UserPassengerRelation.objects.filter(user=user, passenger=passenger).exists():
            return Response({"detail": "您没有权限查看此乘客的证件信息"}, status=status.HTTP_403_FORBIDDEN)

        documents = Document.objects.filter(passenger=passenger)
        serializer = DocumentSerializer(documents, many=True)
        return Response(serializer.data)
