from django.db import models
from user_app.account.models import User


class Level(models.Model):
    LEVEL_CHOICES = (
        (1, 'Lv 1'),
        (2, 'Lv 2'),
        (3, 'Lv 3'),
        (4, 'Lv 4'),
        (5, 'Lv 5'),
        (6, 'Lv 6'),
        (7, '银卡'),
        (8, '金卡'),
        (9, '白金卡'),
    )
    level = models.IntegerField(choices=LEVEL_CHOICES, default=1, verbose_name="会员等级")
    require_miles = models.IntegerField(verbose_name="所需里程")
    require_tickets = models.IntegerField(verbose_name="所需购票次数")
    privileges = models.TextField(verbose_name="等级权益", blank=True, null=True)
    upgrade_info = models.TextField(verbose_name="升级说明", blank=True, null=True)

    class Meta:
        verbose_name = "会员等级"
        verbose_name_plural = "会员等级管理"

    def __str__(self):
        level_name = dict(self.LEVEL_CHOICES).get(self.level, f"Lv {self.level}")
        return f"{level_name} (需里程: {self.require_miles}, 需购票数: {self.require_tickets})"


class Promotion(models.Model):
    name = models.CharField(max_length=255, verbose_name="活动名称")
    description = models.TextField(verbose_name="活动描述")
    start_date = models.DateField(verbose_name="开始日期")
    end_date = models.DateField(verbose_name="结束日期")
    level = models.ForeignKey(Level, on_delete=models.CASCADE, related_name="promotions", verbose_name="适用等级")

    class Meta:
        verbose_name = "优惠活动"
        verbose_name_plural = "优惠活动管理"

    def __str__(self):
        return f"活动: {self.name} (适用等级: {self.level})"
