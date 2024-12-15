# Generated by Django 5.1.3 on 2024-12-14 15:52

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('account', '0001_initial'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='passenger',
            options={'verbose_name': '乘客', 'verbose_name_plural': '乘客管理'},
        ),
        migrations.AlterModelOptions(
            name='user',
            options={'verbose_name': '用户', 'verbose_name_plural': '用户管理'},
        ),
        migrations.AlterField(
            model_name='passenger',
            name='gender',
            field=models.BooleanField(choices=[(True, '男'), (False, '女')]),
        ),
        migrations.AlterField(
            model_name='passenger',
            name='person_type',
            field=models.CharField(choices=[('adult', '成人'), ('student', '学生'), ('teacher', '教师'), ('senior', '老人')], default='adult', max_length=10),
        ),
        migrations.AlterField(
            model_name='user',
            name='accumulated_miles',
            field=models.FloatField(default=0, verbose_name='累计里程'),
        ),
        migrations.AlterField(
            model_name='user',
            name='email',
            field=models.EmailField(max_length=254, unique=True, verbose_name='邮箱'),
        ),
        migrations.AlterField(
            model_name='user',
            name='name',
            field=models.CharField(max_length=255, unique=True, verbose_name='用户名'),
        ),
        migrations.AlterField(
            model_name='user',
            name='password',
            field=models.CharField(max_length=255, verbose_name='密码'),
        ),
        migrations.AlterField(
            model_name='user',
            name='phone_number',
            field=models.CharField(blank=True, max_length=15, null=True, verbose_name='手机号'),
        ),
        migrations.AlterField(
            model_name='user',
            name='ticked_count',
            field=models.IntegerField(default=0, verbose_name='已购票数'),
        ),
    ]