from datetime import datetime

from django.db import models
from django.utils.timezone import is_aware, make_aware
from pypinyin import pinyin, Style

from user_app.account.models import Passenger


# Create your models here.
class Plane(models.Model):
    plane_id = models.CharField(max_length=6, primary_key=True)
    model = models.CharField(max_length=100)
    first_class_seats = models.IntegerField()  # 头等舱座位数
    business_seats = models.IntegerField()  # 商务舱座位数
    economy_seats = models.IntegerField()  # 经济舱座位数

    def __str__(self):
        return f"Plane {self.plane_id} - {self.model}"


class Airport(models.Model):
    airport_code = models.CharField(max_length=4, primary_key=True)
    airport_code_3 = models.CharField(max_length=3)  # 机场三字编码
    airport_name = models.CharField(max_length=100)  # 机场名称
    city = models.ForeignKey('City', on_delete=models.CASCADE, related_name='city')  # 所在城市

    def __str__(self):
        return f"{self.airport_name} ({self.airport_code})"


class Flight(models.Model):
    flight_id = models.IntegerField(primary_key=True)  # 航班号
    departure_time = models.DateTimeField()  # 起飞时间
    arrival_time = models.DateTimeField()  # 到达时间
    departure_airport = models.ForeignKey(Airport, on_delete=models.CASCADE, related_name='departure_airport')  # 起飞机场
    arrival_airport = models.ForeignKey(Airport, on_delete=models.CASCADE, related_name='arrival_airport')  # 到达机场
    remaining_first_class_seats = models.IntegerField()  # 剩余头等舱座位数
    remaining_business_seats = models.IntegerField()  # 剩余商务舱座位数
    remaining_economy_seats = models.IntegerField()  # 剩余经济舱座位数
    distance = models.FloatField()  # 航程距离
    plane = models.ForeignKey(Plane, on_delete=models.CASCADE, related_name='plane')  # 飞机型号

    def __str__(self):
        return f"Flight {self.flight_id} - {self.departure_airport} to {self.arrival_airport} - {self.departure_time} to {self.arrival_time}"


class City(models.Model):
    city_code = models.CharField(max_length=10, primary_key=True)
    city_name = models.CharField(max_length=100)  # 城市名称
    province = models.CharField(max_length=100)  # 省份
    pinyin = models.CharField(max_length=100, blank=True, null=True)  # 存储拼音，用于排序

    def save(self, *args, **kwargs):
        # 使用 pinyin 函数将城市名称转换为拼音的首字母
        # pinyin 返回一个二维列表 [['B'], ['J'], ['H']]，我们需要提取首字母并拼接成字符串
        self.pinyin = ''.join([item[0][0] for item in pinyin(str(self.city_name), style=Style.FIRST_LETTER)])
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.city_name} ({self.city_code})"


class Ticket(models.Model):
    ticket_id = models.AutoField(primary_key=True)  # 机票唯一标识符
    price = models.FloatField()  # 机票价格
    baggage_allowance = models.FloatField()  # 托运行李重量
    ticket_type = models.CharField(max_length=50,
                                   choices=[('adult', 'Adult'),
                                            ('student', 'Student'),
                                            ('teacher', 'Teacher'),
                                            ('senior', 'Senior Citizen')])  # 票类型（成人票、学生票、教师票、老年票等）

    # 增加座位类型字段
    seat_type = models.CharField(max_length=50,
                                 choices=[('economy', 'Economy'),
                                          ('business', 'Business'),
                                          ('first_class', 'First Class')])  # 座位类型（经济舱、商务舱、头等舱）

    flight = models.ForeignKey(Flight, on_delete=models.CASCADE, related_name='tickets')  # 关联航班

    def __str__(self):
        return f"Ticket {self.ticket_id} - {self.ticket_type} - {self.seat_type} - {self.price} USD"

    class Meta:
        verbose_name = "Ticket"
        verbose_name_plural = "Tickets"


class Order(models.Model):
    order_id = models.AutoField(primary_key=True)  # 订单唯一标识符
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE, related_name='orders')  # 乘机人
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='orders')  # 机票
    purchase_time = models.DateTimeField(auto_now_add=True)  # 购买时间
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('confirmed', 'Confirmed'),
            ('canceled', 'Canceled'),
            ('refunded', 'Refunded')
        ],
        default='pending'
    )  # 订单状态
    total_price = models.FloatField()  # 总价格（可以是多个机票的总和）
    refund_amount = models.FloatField(null=True, blank=True)  # 退款金额
    refund_time = models.DateTimeField(null=True, blank=True)  # 退款时间

    def can_cancel(self):
        """
        判断订单是否可以取消（航班未起飞且未取消或退款）。
        """
        current_time = datetime.now()  # 使用 offset-naive 的当前时间

        # 如果航班的时间是 offset-aware，将当前时间也转换为 offset-aware
        if is_aware(self.ticket.flight.departure_time):
            current_time = make_aware(current_time)

        if self.ticket.flight.departure_time > current_time and self.status in ['confirmed']:
            return True
        return False

    def cancel_order(self):
        """
        取消订单并计算退款金额，同时退还座位。
        """
        if not self.can_cancel():
            raise ValueError("Order cannot be canceled.")

        # 更新订单状态和退款信息
        self.status = 'canceled'
        self.refund_amount = self.total_price * 0.8  # 假设退款金额为 80%
        self.refund_time = datetime.now()  # 使用 offset-naive 的当前时间
        self.save()

        # 退还座位
        flight = self.ticket.flight
        if self.ticket.seat_type == 'economy':
            flight.remaining_economy_seats += 1
        elif self.ticket.seat_type == 'business':
            flight.remaining_business_seats += 1
        elif self.ticket.seat_type == 'first_class':
            flight.remaining_first_class_seats += 1

        flight.save()

    def save(self, *args, **kwargs):
        # 验证乘客类型与机票类型是否匹配
        if self.passenger.person_type != self.ticket.ticket_type:
            raise ValueError(
                f"Ticket type '{self.ticket.ticket_type}' does not match passenger type '{self.passenger.person_type}'.")

        # 保存订单
        super().save(*args, **kwargs)

    def is_flight_departed(self):
        """检查航班是否已起飞"""
        return self.ticket.flight.departure_time <= datetime.now()

    def __str__(self):
        return f"Order {self.order_id} - {self.passenger.name} - {self.ticket.ticket_type} - {self.purchase_time}"

    class Meta:
        verbose_name = "Order"
        verbose_name_plural = "Orders"
