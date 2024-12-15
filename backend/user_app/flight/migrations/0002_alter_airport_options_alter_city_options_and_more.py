# Generated by Django 5.1.3 on 2024-12-14 15:52

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('flight', '0001_initial'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='airport',
            options={'verbose_name': '机场', 'verbose_name_plural': '机场管理'},
        ),
        migrations.AlterModelOptions(
            name='city',
            options={'verbose_name': '城市', 'verbose_name_plural': '城市管理'},
        ),
        migrations.AlterModelOptions(
            name='flight',
            options={'verbose_name': '航班', 'verbose_name_plural': '航班管理'},
        ),
        migrations.AlterModelOptions(
            name='order',
            options={'verbose_name': '订单', 'verbose_name_plural': '订单管理'},
        ),
        migrations.AlterModelOptions(
            name='plane',
            options={'verbose_name': '飞机', 'verbose_name_plural': '飞机管理'},
        ),
        migrations.AlterModelOptions(
            name='ticket',
            options={'verbose_name': '机票', 'verbose_name_plural': '机票管理'},
        ),
        migrations.AlterField(
            model_name='airport',
            name='airport_code',
            field=models.CharField(max_length=4, primary_key=True, serialize=False, verbose_name='机场代码'),
        ),
        migrations.AlterField(
            model_name='airport',
            name='airport_code_3',
            field=models.CharField(max_length=3, verbose_name='机场三字码'),
        ),
        migrations.AlterField(
            model_name='airport',
            name='airport_name',
            field=models.CharField(max_length=100, verbose_name='机场名称'),
        ),
        migrations.AlterField(
            model_name='airport',
            name='city',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='city', to='flight.city', verbose_name='所在城市'),
        ),
        migrations.AlterField(
            model_name='city',
            name='city_code',
            field=models.CharField(max_length=10, primary_key=True, serialize=False, verbose_name='城市代码'),
        ),
        migrations.AlterField(
            model_name='city',
            name='city_name',
            field=models.CharField(max_length=100, verbose_name='城市名称'),
        ),
        migrations.AlterField(
            model_name='city',
            name='pinyin',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='拼音'),
        ),
        migrations.AlterField(
            model_name='city',
            name='province',
            field=models.CharField(max_length=100, verbose_name='省份'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='arrival_airport',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='arrival_airport', to='flight.airport', verbose_name='到达机场'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='arrival_time',
            field=models.DateTimeField(verbose_name='到达时间'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='departure_airport',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='departure_airport', to='flight.airport', verbose_name='起飞机场'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='departure_time',
            field=models.DateTimeField(verbose_name='起飞时间'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='distance',
            field=models.FloatField(verbose_name='航程距离'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='flight_id',
            field=models.IntegerField(primary_key=True, serialize=False, verbose_name='航班号'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='plane',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='plane', to='flight.plane', verbose_name='飞机'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='remaining_business_seats',
            field=models.IntegerField(verbose_name='剩余商务舱座位数'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='remaining_economy_seats',
            field=models.IntegerField(verbose_name='剩余经济舱座位数'),
        ),
        migrations.AlterField(
            model_name='flight',
            name='remaining_first_class_seats',
            field=models.IntegerField(verbose_name='剩余头等舱座位数'),
        ),
        migrations.AlterField(
            model_name='order',
            name='refund_amount',
            field=models.FloatField(blank=True, null=True, verbose_name='退款金额'),
        ),
        migrations.AlterField(
            model_name='order',
            name='refund_time',
            field=models.DateTimeField(blank=True, null=True, verbose_name='退款时间'),
        ),
        migrations.AlterField(
            model_name='order',
            name='status',
            field=models.CharField(choices=[('pending', '待支付'), ('confirmed', '已确认'), ('canceled', '已取消'), ('refunded', '已退款')], default='pending', max_length=20, verbose_name='订单状态'),
        ),
        migrations.AlterField(
            model_name='order',
            name='total_price',
            field=models.FloatField(verbose_name='总价格'),
        ),
        migrations.AlterField(
            model_name='plane',
            name='business_seats',
            field=models.IntegerField(verbose_name='商务舱座位数'),
        ),
        migrations.AlterField(
            model_name='plane',
            name='economy_seats',
            field=models.IntegerField(verbose_name='经济舱座位数'),
        ),
        migrations.AlterField(
            model_name='plane',
            name='first_class_seats',
            field=models.IntegerField(verbose_name='头等舱座位数'),
        ),
        migrations.AlterField(
            model_name='plane',
            name='model',
            field=models.CharField(max_length=100, verbose_name='飞机型号'),
        ),
        migrations.AlterField(
            model_name='plane',
            name='plane_id',
            field=models.CharField(max_length=6, primary_key=True, serialize=False, verbose_name='飞机编号'),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='baggage_allowance',
            field=models.FloatField(verbose_name='行李限额（公斤）'),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='flight',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tickets', to='flight.flight', verbose_name='航班'),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='price',
            field=models.FloatField(verbose_name='票价'),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='seat_type',
            field=models.CharField(choices=[('economy', '经济舱'), ('business', '商务舱'), ('first_class', '头等舱')], max_length=50),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='ticket_id',
            field=models.AutoField(primary_key=True, serialize=False, verbose_name='机票号'),
        ),
        migrations.AlterField(
            model_name='ticket',
            name='ticket_type',
            field=models.CharField(choices=[('adult', '成人票'), ('student', '学生票'), ('teacher', '教师票'), ('senior', '老年票')], max_length=50),
        ),
    ]