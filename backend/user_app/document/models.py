# Create your models here.
from django.db import models
from user_app.account.models import Passenger  # 导入Passenger模型


class Document(models.Model):
    DOCUMENT_TYPE_CHOICES = [
        ('id_card', '身份证'),  # 身份证
        ('passport', '护照'),  # 护照
        ('hukou booklet', '户口簿'),  # 户口簿
        ('birth certificate', '出生证明'),  # 出生证明
        ('other', '其他'),  # 其他
        # 其他证件类型...
    ]

    document_id = models.AutoField(primary_key=True, verbose_name='证件ID')  # 证件ID
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPE_CHOICES, verbose_name='证件类型')  # 证件类型
    document_number = models.CharField(max_length=100, unique=True, verbose_name='证件号')  # 证件号
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE, related_name='documents', verbose_name='乘客')  # 外键，连接到Passenger模型

    class Meta:
        verbose_name = "证件"
        verbose_name_plural = "证件管理"

    def __str__(self):
        return f"{self.document_type} - {self.document_number} for {self.passenger.name}"
