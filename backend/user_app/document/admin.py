from django.contrib import admin
from user_app.document.models import Document
from backend.admin_site import custom_admin_site


# Register your models here.
@admin.register(Document, site=custom_admin_site)
class DocumentAdmin(admin.ModelAdmin):
    # 列表显示字段
    list_display = ('document_id', 'document_type', 'document_number', 'passenger')
    # 列表筛选字段
    list_filter = ('document_type',)
    # 搜索字段
    search_fields = ('document_number', 'passenger__name')
    # 每页显示的条目数
    list_per_page = 20

    # 自定义显示的中文化描述
    list_display_links = ('document_number',)  # 让证件号可点击，跳转到编辑页面
    ordering = ('document_id',)  # 按证件ID排序
    actions = ['delete_documents']  # 自定义操作按钮

    # 添加字段展示形式
    fieldsets = (
        (None, {
            'fields': ('document_type', 'document_number', 'passenger'),
        }),
    )
