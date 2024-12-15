# Generated by Django 5.1.3 on 2024-12-15 12:44

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('level', '0002_alter_level_options_alter_level_level_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='level',
            name='privileges',
            field=models.TextField(blank=True, null=True, verbose_name='等级权益'),
        ),
        migrations.AddField(
            model_name='level',
            name='upgrade_info',
            field=models.TextField(blank=True, null=True, verbose_name='升级说明'),
        ),
    ]