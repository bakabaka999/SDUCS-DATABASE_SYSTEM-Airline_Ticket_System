from django.db import models


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
    province = models.CharField(max_length=100)  # 省份
    city = models.CharField(max_length=100)  # 城市

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


class Ticket(models.Model):
    ticket_id = models.IntegerField(primary_key=True)  # 机票号
    price = models.FloatField()  # 票价


