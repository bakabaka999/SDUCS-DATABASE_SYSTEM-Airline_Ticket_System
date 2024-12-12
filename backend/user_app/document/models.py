# Create your models here.
from django.db import models
from user_app.account.models import Passenger  # 导入Passenger模型


class Document(models.Model):
    DOCUMENT_TYPE_CHOICES = [
        ('id_card', 'ID Card'),  # 身份证
        ('passport', 'Passport'),  # 护照
        ('hukou booklet', 'Hukou Booklet'),  # 户口簿
        ('birth certificate', 'Birth Certificate'),  # 出生证明
        ('other', 'Other'),  # 其他
        # 其他证件类型...
    ]

    document_id = models.AutoField(primary_key=True)  # 证件ID
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPE_CHOICES)  # 证件类型
    document_number = models.CharField(max_length=100, unique=True)  # 证件号
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE, related_name='documents')  # 外键，连接到Passenger模型

    class Meta:
        verbose_name = "Document"
        verbose_name_plural = "Documents"

    def __str__(self):
        return f"{self.document_type} - {self.document_number} for {self.passenger.name}"
