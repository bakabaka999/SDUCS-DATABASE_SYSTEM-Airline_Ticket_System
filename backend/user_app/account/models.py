from django.db import models


# Create your models here.
class User(models.Model):
    name = models.CharField(max_length=255, unique=True, verbose_name='用户名')
    email = models.EmailField(unique=True, verbose_name='邮箱')
    phone_number = models.CharField(max_length=15, null=True, blank=True, verbose_name='手机号')
    password = models.CharField(max_length=255, verbose_name='密码')  # 后期可以加上加密

    # 账户信息
    accumulated_miles = models.FloatField(default=0, verbose_name='累计里程')  # 累计里程
    ticked_count = models.IntegerField(default=0, verbose_name='已购票数')  # 购票次数

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = '用户'
        verbose_name_plural = '用户管理'


# 乘客信息
class Passenger(models.Model):
    GENDER_CHOICES = [
        (True, '男'),
        (False, '女')
    ]

    PERSON_TYPE_CHOICES = [
        ('adult', '成人'),
        ('student', '学生'),
        ('teacher', '教师'),
        ('senior', '老人')
    ]

    name = models.CharField(max_length=100)  # 乘客姓名
    gender = models.BooleanField(choices=GENDER_CHOICES)  # 性别
    phone_number = models.CharField(max_length=15)  # 手机号
    email = models.EmailField(null=True, blank=True)  # 邮箱
    person_type = models.CharField(max_length=10, choices=PERSON_TYPE_CHOICES, default='adult')  # 乘客类型
    birth_date = models.DateField(null=True, blank=True)  # 出生日期

    class Meta:
        verbose_name = "乘客"
        verbose_name_plural = "乘客管理"

    def __str__(self):
        return self.name


class UserPassengerRelation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="passengers")
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE, related_name="users")

    class Meta:
        unique_together = ('user', 'passenger')  # 保证每个用户-乘机人组合唯一

    def __str__(self):
        return f"{self.user.name} - {self.passenger.name}"


# 发票信息
class Invoice(models.Model):
    INVOICE_TYPE_CHOICES = [
        ('digital', 'Digital Invoice'),
        ('paper', 'Paper Invoice'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(max_length=255, choices=INVOICE_TYPE_CHOICES)  # 发票类型
    name = models.CharField(max_length=255)  # 收票人姓名
    identification_number = models.CharField(max_length=50, null=True, blank=True)  # 身份证号
    company_address = models.CharField(max_length=255)  # 公司地址
    phone_number = models.CharField(max_length=15)  # 手机号
    bank_name = models.CharField(max_length=255)  # 银行名称
    bank_account = models.CharField(max_length=50)  # 银行账号

    def __str__(self):
        return f'{self.name} - {self.type}'
