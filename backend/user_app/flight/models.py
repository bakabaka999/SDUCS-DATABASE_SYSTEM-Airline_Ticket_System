from datetime import datetime

from django.db import models
from django.utils.timezone import is_aware, make_aware
from pypinyin import pinyin, Style

from user_app.account.models import Passenger, User, UserPassengerRelation


# Create your models here.
class Plane(models.Model):
    plane_id = models.CharField(max_length=6, primary_key=True, verbose_name="飞机编号")
    model = models.CharField(max_length=100, verbose_name="飞机型号")
    first_class_seats = models.IntegerField(verbose_name="头等舱座位数")  # 头等舱座位数
    business_seats = models.IntegerField(verbose_name="商务舱座位数")  # 商务舱座位数
    economy_seats = models.IntegerField(verbose_name="经济舱座位数")  # 经济舱座位数

    class Meta:
        verbose_name = "飞机"
        verbose_name_plural = "飞机管理"

    def __str__(self):
        return f"飞机 {self.plane_id} - {self.model}"


class Airport(models.Model):
    airport_code = models.CharField(max_length=4, primary_key=True, verbose_name="机场代码")
    airport_code_3 = models.CharField(max_length=3, verbose_name="机场三字码")  # 机场三字编码
    airport_name = models.CharField(max_length=100, verbose_name="机场名称")  # 机场名称
    city = models.ForeignKey('City', on_delete=models.CASCADE, related_name='city', verbose_name="所在城市")  # 所在城市

    class Meta:
        verbose_name = "机场"
        verbose_name_plural = "机场管理"

    def __str__(self):
        return f"{self.airport_name} ({self.airport_code})"


class Flight(models.Model):
    flight_id = models.IntegerField(primary_key=True, verbose_name="航班号")  # 航班号
    departure_time = models.DateTimeField(verbose_name="起飞时间")  # 起飞时间
    arrival_time = models.DateTimeField(verbose_name="到达时间")  # 到达时间
    departure_airport = models.ForeignKey(Airport, on_delete=models.CASCADE, related_name='departure_airport', verbose_name="起飞机场")  # 起飞机场
    arrival_airport = models.ForeignKey(Airport, on_delete=models.CASCADE, related_name='arrival_airport', verbose_name="到达机场")  # 到达机场
    remaining_first_class_seats = models.IntegerField(verbose_name="剩余头等舱座位数")  # 剩余头等舱座位数
    remaining_business_seats = models.IntegerField(verbose_name="剩余商务舱座位数")  # 剩余商务舱座位数
    remaining_economy_seats = models.IntegerField(verbose_name="剩余经济舱座位数")  # 剩余经济舱座位数
    distance = models.FloatField(verbose_name="航程距离")  # 航程距离
    plane = models.ForeignKey(Plane, on_delete=models.CASCADE, related_name='plane', verbose_name="飞机")  # 飞机型号

    class Meta:
        verbose_name = "航班"
        verbose_name_plural = "航班管理"

    def __str__(self):
        return f"航班 {self.flight_id} - {self.departure_airport} to {self.arrival_airport} - {self.departure_time} to {self.arrival_time}"


class City(models.Model):
    city_code = models.CharField(max_length=10, primary_key=True, verbose_name="城市代码")
    city_name = models.CharField(max_length=100, verbose_name="城市名称")  # 城市名称
    province = models.CharField(max_length=100, verbose_name="省份")  # 省份
    pinyin = models.CharField(max_length=100, blank=True, null=True, verbose_name="拼音")  # 存储拼音，用于排序

    class Meta:
        verbose_name = "城市"
        verbose_name_plural = "城市管理"

    def save(self, *args, **kwargs):
        # 使用 pinyin 函数将城市名称转换为拼音的首字母
        # pinyin 返回一个二维列表 [['B'], ['J'], ['H']]，我们需要提取首字母并拼接成字符串
        self.pinyin = ''.join([item[0][0] for item in pinyin(str(self.city_name), style=Style.FIRST_LETTER)])
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.city_name} ({self.city_code})"


class Ticket(models.Model):
    ticket_id = models.AutoField(primary_key=True, verbose_name="机票号")  # 机票唯一标识符
    price = models.FloatField(verbose_name="票价")  # 机票价格
    baggage_allowance = models.FloatField(verbose_name="行李限额（公斤）")  # 托运行李重量
    ticket_type = models.CharField(max_length=50,
                                   choices=[('adult', '成人票'),
                                            ('student', '学生票'),
                                            ('teacher', '教师票'),
                                            ('senior', '老年票')])  # 票类型（成人票、学生票、教师票、老年票等）

    # 增加座位类型字段
    seat_type = models.CharField(max_length=50,
                                 choices=[('economy', '经济舱'),
                                          ('business', '商务舱'),
                                          ('first_class', '头等舱')])  # 座位类型（经济舱、商务舱、头等舱）

    flight = models.ForeignKey(Flight, on_delete=models.CASCADE, related_name='tickets', verbose_name="航班")  # 关联航班

    def __str__(self):
        return f"机票 {self.ticket_id} - {self.ticket_type} - {self.seat_type} - {self.price} USD"

    class Meta:
        verbose_name = "机票"
        verbose_name_plural = "机票管理"


class Order(models.Model):
    order_id = models.AutoField(primary_key=True)  # 订单唯一标识符
    passenger = models.ForeignKey(Passenger, on_delete=models.CASCADE, related_name='orders')  # 乘机人
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='orders')  # 机票
    purchase_time = models.DateTimeField(auto_now_add=True)  # 购买时间
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', '待支付'),
            ('confirmed', '已确认'),
            ('canceled', '已取消'),
            ('refunded', '已退款')
        ],
        default='pending',
        verbose_name="订单状态"
    )  # 订单状态
    total_price = models.FloatField(verbose_name="总价格")  # 总价格（可以是多个机票的总和）
    refund_amount = models.FloatField(null=True, blank=True, verbose_name="退款金额")  # 退款金额
    refund_time = models.DateTimeField(null=True, blank=True, verbose_name="退款时间")  # 退款时间

    def can_cancel(self):
        """
        判断订单是否可以取消（航班未起飞且未取消或退款）。
        """
        current_time = datetime.now()  # 使用 naive 的当前时间

        if is_aware(self.ticket.flight.departure_time):
            # 这一行不再需要，因为禁用时区后，不能使用 make_aware
            pass
        if self.ticket.flight.departure_time > current_time and self.status in ['confirmed', 'pending']:
            return True
        return False

    def cancel_order(self):
        """
        取消订单并计算退款金额，同时退还座位。
        """
        if not self.can_cancel():
            raise ValueError("Order cannot be canceled.")

        # 更新订单状态和退款信息
        if self.status == 'confirmed':
            self.status = 'refunded'
            self.refund_amount = self.total_price * 0.8  # 假设退款金额为 80%
            self.refund_time = datetime.now()  # 使用 offset-naive 的当前时间
            self.save()
        elif self.status == 'pending':
            self.status = 'canceled'
            self.save()

        # 退还座位
        flight = self.ticket.flight
        if self.ticket.seat_type == 'economy':
            flight.remaining_economy_seats += 1
        elif self.ticket.seat_type == 'business':
            flight.remaining_business_seats += 1
        elif self.ticket.seat_type == 'first_class':
            flight.remaining_first_class_seats += 1

        if self.status == 'refunded':
            # 修改用户里程数与购票次数
            user = User.objects.get(
                id=UserPassengerRelation.objects.get(passenger=self.passenger).user_id
            )
            user.accumulated_miles -= self.ticket.flight.distance
            user.ticked_count -= 1
            user.save()

        flight.save()

    def save(self, *args, **kwargs):
        # 验证乘客类型与机票类型是否匹配
        if self.ticket.ticket_type != 'adult' and self.passenger.person_type != self.ticket.ticket_type:
            raise ValueError(
                f"Ticket type '{self.ticket.ticket_type}' does not match passenger type '{self.passenger.person_type}'.")

        # 保存订单
        super().save(*args, **kwargs)

    def is_flight_departed(self):
        """检查航班是否已起飞"""
        return self.ticket.flight.departure_time <= datetime.now()

    def __str__(self):
        return f"订单 {self.order_id} - 乘机人： {self.passenger.name} - 机票： {self.ticket.ticket_type} - 购买时间： {self.purchase_time}"

    class Meta:
        verbose_name = "订单"
        verbose_name_plural = "订单管理"


