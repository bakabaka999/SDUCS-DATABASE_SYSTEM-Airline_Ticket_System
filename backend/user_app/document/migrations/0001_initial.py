# Generated by Django 5.1.3 on 2024-12-12 09:07

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('account', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Document',
            fields=[
                ('document_id', models.AutoField(primary_key=True, serialize=False)),
                ('document_type', models.CharField(choices=[('id_card', 'ID Card'), ('passport', 'Passport'), ('hukou booklet', 'Hukou Booklet'), ('birth certificate', 'Birth Certificate'), ('other', 'Other')], max_length=50)),
                ('document_number', models.CharField(max_length=100, unique=True)),
                ('passenger', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='documents', to='account.passenger')),
            ],
            options={
                'verbose_name': 'Document',
                'verbose_name_plural': 'Documents',
            },
        ),
    ]
