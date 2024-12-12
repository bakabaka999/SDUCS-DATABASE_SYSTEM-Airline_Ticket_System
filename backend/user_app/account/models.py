from django.db import models


# Create your models here.
class User(models.Model):
    name = models.CharField(max_length=255, unique=True)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, null=True, blank=True)
    password = models.CharField(max_length=255)  # 后期可以加上加密

    # 账户信息
    accumulated_miles = models.FloatField(default=0)  # 累计里程
    ticked_count = models.IntegerField(default=0)  # 购票次数

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'


# 乘客信息
class Passenger(models.Model):
    GENDER_CHOICES = [
        (True, 'Male'),
        (False, 'Female')
    ]

    PERSON_TYPE_CHOICES = [
        ('adult', 'Adult'),
        ('student', 'Student'),
        ('teacher', 'Teacher'),
        ('senior', 'Senior Citizen')
    ]

    name = models.CharField(max_length=100)  # 乘客姓名
    gender = models.BooleanField(choices=GENDER_CHOICES)  # 性别
    phone_number = models.CharField(max_length=15)  # 手机号
    email = models.EmailField(null=True, blank=True)  # 邮箱
    person_type = models.CharField(max_length=10, choices=PERSON_TYPE_CHOICES, default='adult')  # 乘客类型
    birth_date = models.DateField(null=True, blank=True)  # 出生日期

    class Meta:
        verbose_name = "Passenger"
        verbose_name_plural = "Passengers"

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
