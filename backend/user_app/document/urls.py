from django.urls import path
from .views import DocumentView

urlpatterns = [
    path('', DocumentView.as_view(), name='document-list'),  # 获取或创建证件
    path('<int:document_id>/', DocumentView.as_view(), name='document-detail'),  # 更新或删除证件
]
