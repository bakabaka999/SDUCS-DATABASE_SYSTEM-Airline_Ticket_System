from django.db import models
from user_app.account.models import User


# Create your models here.
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
    level = models.IntegerField(choices=LEVEL_CHOICES, default=1)
    require_miles = models.IntegerField()
    require_tickets = models.IntegerField()

    def __str__(self):
        return f"Level {self.level}"
