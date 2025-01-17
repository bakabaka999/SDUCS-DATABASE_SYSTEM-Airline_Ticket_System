import os

from django.conf import settings
from django.core.exceptions import ObjectDoesNotExist
from rest_framework import status
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User as AuthUser
from .models import User, Passenger, UserPassengerRelation, Invoice
from .serializers import UserSerializer, PassengerSerializer, InvoiceSerializer
from rest_framework.decorators import api_view, permission_classes


# 注册视图：用于处理用户的注册请求
class RegisterView(APIView):
    """
    用户注册接口。用户通过POST请求进行注册，提供用户名、邮箱和密码。
    注册时会检查用户名和邮箱是否已存在，若有冲突则返回错误。
    """
    permission_classes = [AllowAny]  # 允许任何用户访问，无需认证

    @staticmethod
    def post(request):
        # 获取请求体中的字段数据
        username = request.data.get("username")
        email = request.data.get("email")
        password = request.data.get("password")

        # 如果用户名、邮箱或密码为空，返回错误
        if not username or not email or not password:
            return Response({"error": "All fields are required."}, status=status.HTTP_400_BAD_REQUEST)

        # 如果用户名已存在，返回错误
        if AuthUser.objects.filter(username=username).exists():
            return Response({"error": "Username already exists."}, status=status.HTTP_400_BAD_REQUEST)

        # 如果邮箱已存在，返回错误
        if AuthUser.objects.filter(email=email).exists():
            return Response({"error": "Email already registered."}, status=status.HTTP_400_BAD_REQUEST)

        # 创建Django内置的认证用户
        user = AuthUser.objects.create_user(username=username, email=email, password=password)
        # 创建自定义用户模型
        custom_user = User.objects.create(name=user.username, email=user.email, password=password)

        return Response({"message": "User created successfully"}, status=status.HTTP_201_CREATED)


# 登录视图：用于处理用户登录请求
class LoginView(APIView):
    """
    用户登录接口。用户通过POST请求提交用户名和密码，进行身份验证。
    登录成功后会创建会话并返回成功信息；如果登录失败，返回错误信息。
    """
    permission_classes = [AllowAny]  # 允许任何用户访问，无需认证

    def post(self, request):
        # 获取用户名和密码
        username = request.data.get("username")
        password = request.data.get("password")
        print(username, password)

        # 使用Django的认证功能验证用户身份
        user = authenticate(request, username=username, password=password)

        if user is not None:
            # 如果验证通过，登录用户并返回成功响应
            login(request, user)
            # 创建 Token 或获取已有 Token
            token, created = Token.objects.get_or_create(user=user)
            # 返回登录成功的信息和 Token
            return Response({
                "message": "Login successful",
                "token": token.key  # 将 Token 返回给前端
            }, status=status.HTTP_200_OK)

        # 如果用户名或密码错误，返回错误响应
        return Response({"error": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)


class ValidateTokenView(APIView):
    """
    用于验证Token是否有效
    """
    permission_classes = [IsAuthenticated]  # 确保只有携带有效Token的用户能访问

    @staticmethod
    def get(request):
        # 如果用户通过了IsAuthenticated的认证，则Token是有效的
        return Response({"message": "Token is valid"}, status=200)


# 获取用户个人信息：用户通过此接口可以查看自己账户的基本信息
class UserProfileView(APIView):
    """
    用户个人信息接口。用户通过GET请求查看自己的账户信息（如用户名、邮箱、累计里程等）。
    通过PUT请求，用户可以修改自己的信息（如手机号、邮箱等）。
    """
    permission_classes = [IsAuthenticated]  # 只有认证通过的用户才能访问此接口

    @staticmethod
    def get(request):
        # 验证 Token
        try:
            token = request.headers.get('Authorization').split(' ')[1]  # 获取Bearer Token
            token_obj = Token.objects.get(key=token)
            user = token_obj.user
        except Token.DoesNotExist:
            raise AuthenticationFailed('Invalid Token')
        # 获取自定义User模型的数据
        user_info = User.objects.get(name=user.username)
        # 序列化用户数据
        serializer = UserSerializer(user_info)
        return Response(serializer.data)

    @staticmethod
    def put(request):
        # 获取当前登录的用户
        user = request.user  # 获取当前认证用户

        # 获取自定义User模型的数据
        user_info = User.objects.get(name=user.username)

        # 获取Django的内置认证用户模型
        django_user = AuthUser.objects.get(id=user.id)  # 获取Django认证的User对象

        # 使用序列化器更新自定义用户模型数据
        serializer = UserSerializer(user_info, data=request.data, partial=True)

        if serializer.is_valid():
            # 更新自定义模型的数据
            updated_user = serializer.save()

            # 同时更新Django内置的认证用户模型（如果有相关字段变动）
            if 'name' in request.data:  # 检查是否有更新用户名
                django_user.username = request.data['name']  # 更新Django认证模型的用户名
            if 'email' in request.data:  # 更新email字段
                django_user.email = request.data['email']
            django_user.save()  # 保存Django内置的User模型

            # 返回更新后的用户数据
            return Response(UserSerializer(updated_user).data)

        else:
            # 如果数据无效，返回错误
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 乘机人管理视图：用户可以通过此接口管理常用的乘机人信息
class PassengerView(APIView):
    """
    乘机人信息管理接口。用户可以通过POST请求添加乘机人信息，PUT请求更新乘机人信息，DELETE请求删除乘机人信息。
    """
    permission_classes = [IsAuthenticated]  # 只有认证通过的用户才能访问此接口

    @staticmethod
    def get(request):
        # 获取当前登录的用户
        user = request.user

        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        try:
            # 获取当前用户所有的乘机人
            user_passengers = UserPassengerRelation.objects.filter(user=user)
            passengers = [relation.passenger for relation in user_passengers]
            # 序列化乘机人数据
            serializer = PassengerSerializer(passengers, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            # 捕获异常并返回错误
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @staticmethod
    def post(request):
        # 获取当前登录的用户
        user = request.user

        # 确保 user 是一个有效的 User 实例
        if not user or not hasattr(user, 'id'):
            return Response({"detail": "用户无效或未登录"}, status=status.HTTP_400_BAD_REQUEST)

        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 使用序列化器验证和创建乘机人信息
        serializer = PassengerSerializer(data=request.data)
        if serializer.is_valid():
            try:
                # 创建乘机人
                passenger = serializer.save()

                # 确保乘机人没有重复
                if UserPassengerRelation.objects.filter(user=user, passenger=passenger).exists():
                    return Response({"detail": "该乘客已被添加至您的常用乘机人列表"},
                                    status=status.HTTP_400_BAD_REQUEST)

                # 创建用户和乘机人之间的关系
                UserPassengerRelation.objects.create(user=user, passenger=passenger)

                # 返回成功响应
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            except Exception as e:
                # 捕获异常，返回详细错误信息
                return Response({"detail": f"创建关系失败: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            # 如果序列化器数据无效，返回错误
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def put(request, pk):
        # 获取当前登录的用户
        user = request.user

        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 获取需要更新的乘机人（通过关联表查询）
        try:
            relation = UserPassengerRelation.objects.get(user=user, passenger__id=pk)
            passenger = relation.passenger
        except UserPassengerRelation.DoesNotExist:
            return Response({"error": "Passenger not found or not associated with the user."},
                            status=status.HTTP_404_NOT_FOUND)

        # 使用序列化器更新乘机人数据
        serializer = PassengerSerializer(passenger, data=request.data, partial=True)
        if serializer.is_valid():
            # 保存更新后的数据
            serializer.save()
            return Response(serializer.data)

        # 如果数据无效，返回错误
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def delete(request, pk):
        # 获取当前登录的用户
        user = request.user

        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(name=user.username)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)

        # 获取并删除指定ID的乘机人（通过关联表查询）
        try:
            relation = UserPassengerRelation.objects.get(user=user, passenger__id=pk)
            passenger = relation.passenger
            passenger.delete()
            relation.delete()  # 删除关联关系
            return Response({"message": "Passenger deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
        except UserPassengerRelation.DoesNotExist:
            return Response({"error": "Passenger not found or not associated with the user."},
                            status=status.HTTP_404_NOT_FOUND)


# 发票信息管理视图：用户可以通过此接口管理常用的发票信息
class InvoiceView(APIView):
    """
    发票管理接口。用户可以通过POST请求添加发票信息，PUT请求更新发票信息，DELETE请求删除发票信息。
    """
    permission_classes = [IsAuthenticated]  # 只有认证通过的用户才能访问此接口

    @staticmethod
    def get(request):
        # 获取当前登录的用户
        user = request.user
        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)
        try:
            # 获取当前用户的所有发票信息
            invoices = Invoice.objects.filter(user=user)
            serializer = InvoiceSerializer(invoices, many=True)
            return Response(serializer.data)
        except Exception as e:
            # 捕获异常并返回错误
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @staticmethod
    def post(request):
        # 获取当前登录的用户
        user = request.user
        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)
        # 使用序列化器验证和创建发票信息
        serializer = InvoiceSerializer(data=request.data)
        if serializer.is_valid():
            # 创建发票并关联到用户
            invoice = serializer.save(user=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        # 如果数据无效，返回错误
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def put(request, pk):
        # 获取当前登录的用户
        user = request.user
        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)
        # 获取并更新指定ID的发票信息
        invoice = Invoice.objects.get(id=pk, user=user)
        serializer = InvoiceSerializer(invoice, data=request.data, partial=True)
        if serializer.is_valid():
            # 保存更新后的数据
            serializer.save()
            return Response(serializer.data)
        # 如果数据无效，返回错误
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @staticmethod
    def delete(request, pk):
        # 获取当前登录的用户
        user = request.user
        # 显式获取 user 实例，避免 SimpleLazyObject 问题
        try:
            user = User.objects.get(id=user.id)
        except ObjectDoesNotExist:
            return Response({"detail": "用户未找到"}, status=status.HTTP_404_NOT_FOUND)
        # 获取并删除指定ID的发票信息
        invoice = Invoice.objects.get(id=pk, user=user)
        invoice.delete()
        return Response({"message": "Invoice deleted successfully"}, status=status.HTTP_204_NO_CONTENT)


# 资质认证视图：用户可以提交资质认证请求
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def qualification_certification(request):
    """
    资质认证接口。用户可以提交不同类型的认证请求（例如：学生认证、教师认证、老年人认证等）。
    提交认证类型后会进行相关的认证处理。
    """
    certification_type = request.data.get('certification_type')
    if certification_type not in ['student', 'teacher', 'adult', 'senior']:
        return Response({"error": "Invalid certification type."}, status=status.HTTP_400_BAD_REQUEST)

    # 在此可以处理资质认证逻辑，例如保存认证信息等
    return Response({"message": "Certification successful"}, status=status.HTTP_200_OK)

# 修改密码视图：用户可以修改密码
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    修改用户密码接口。用户通过PUT请求提供旧密码和新密码。
    """
    user = request.user  # 获取当前登录的用户
    old_password = request.data.get("old_password")
    new_password = request.data.get("new_password")

    # 使用Django的认证功能验证用户身份
    user = authenticate(request, username=user.username, password=old_password)

    if user is not None:
        # 设置新密码（更新自定义用户模型）
        user.password = new_password
        user.save()
        # 更新Django认证用户（AuthUser）的密码
        try:
            django_user = AuthUser.objects.get(id=user.id)  # 获取对应的Django认证用户
            django_user.set_password(new_password)  # 设置新密码
            django_user.save()  # 保存更新后的Django认证用户密码
        except AuthUser.DoesNotExist:
            return Response({"error": "Django user not found."}, status=status.HTTP_400_BAD_REQUEST)
        return Response({"message": "Password updated successfully."}, status=status.HTTP_200_OK)
    else:
        return Response({"error": "Old password is incorrect."}, status=status.HTTP_400_BAD_REQUEST)


# 退出登录视图：用户可以退出登录
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """
    处理用户退出登录。
    """

    try:
        logout(request)
        return Response({"detail": "Successfully logged out."}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class UploadAvatarView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    @staticmethod
    def post(request, *args, **kwargs):
        try:
            user = request.user
            if not user.is_authenticated:
                return Response({'error': '用户未登录'}, status=status.HTTP_401_UNAUTHORIZED)
            user = User.objects.get(name=user.username)

            # 检查是否上传了头像文件
            new_avatar = request.FILES.get('avatar')
            if not new_avatar:
                return Response({'error': '请提供头像文件'}, status=status.HTTP_400_BAD_REQUEST)

            # 删除旧头像（如果存在且是用户上传的头像）
            if user.avatar and user.avatar.name != 'avatars/default_avatar.png':
                old_avatar_path = os.path.join(settings.MEDIA_ROOT, str(user.avatar))
                if os.path.exists(old_avatar_path):
                    os.remove(old_avatar_path)

            # 保存新头像
            user.avatar = new_avatar
            user.save()

            # 返回新的头像 URL
            return Response({
                'message': '头像上传成功',
                'avatar_url': request.build_absolute_uri(user.avatar.url)
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'error': f'发生错误: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
