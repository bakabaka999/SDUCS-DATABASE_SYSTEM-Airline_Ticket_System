# app_name/urls.py
from django.urls import path
from .views import RegisterView, LoginView, UserProfileView, PassengerView, InvoiceView, qualification_certification, \
    logout_view, change_password, ValidateTokenView, UploadAvatarView

urlpatterns = [
    # 用户注册接口
    path('register/', RegisterView.as_view(), name='register'),

    # 用户登录接口
    path('login/', LoginView.as_view(), name='login'),

    # token验证接口
    path('token/', ValidateTokenView.as_view(), name='validate_token'),

    # 用户个人信息接口
    path('profile/', UserProfileView.as_view(), name='user_profile'),

    # 用户头像上传接口
    path('profile/avatar/', UploadAvatarView.as_view(), name='upload_avatar'),  # 新增头像上传接口

    # 乘机人管理接口
    path('passenger/', PassengerView.as_view(), name='passenger_list'),  # 添加、获取乘机人
    path('passenger/<int:pk>/', PassengerView.as_view(), name='passenger_detail'),  # 修改、删除指定乘机人

    # 发票信息管理接口
    path('invoice/', InvoiceView.as_view(), name='invoice_list'),  # 添加发票
    path('invoice/<int:pk>/', InvoiceView.as_view(), name='invoice_detail'),  # 修改或删除指定发票

    # 资质认证接口
    path('qualification/', qualification_certification, name='qualification_certification'),

    # 密码修改接口
    path('change-password/', change_password, name='change_password'),

    # 退出登录接口
    path('logout/', logout_view, name='logout'),
]
