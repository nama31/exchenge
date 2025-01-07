from django.db import models
# Create your models here.
# users_and_trades/models.py
from django.contrib.auth.models import User

class User(models.Model):
    name = models.CharField(max_length=100)
    password = models.IntegerField()

    def _str_(self):
        return self.name



class Trade(models.Model):
    currency = models.CharField(max_length=10)
    amount = models.DecimalField(max_digits=20, decimal_places=2)
    price = models.DecimalField(max_digits=20, decimal_places=2)
    total = models.DecimalField(max_digits=20, decimal_places=2)
    type = models.CharField(max_length=10, choices=[('buy', 'Buy'), ('sell', 'Sell')], default='buy')
    created_at = models.DateTimeField(auto_now_add=True)


class Currency(models.Model):
    name = models.CharField(max_length=100, unique=True)
    buy_price = models.DecimalField(max_digits=10, decimal_places=2)  # Цена покупки
    sell_price = models.DecimalField(max_digits=10, decimal_places=2)  # Цена продажи

    def __str__(self):
        return f"{self.name} - Buy: {self.buy_price}, Sell: {self.sell_price}"

    class Meta:
        verbose_name = 'Currency'
        verbose_name_plural = 'Currencies'
        db_table = 'currencies'  # Убедитесь, что имя таблицы указано корректно


class CurrencyReport(models.Model):
    currency = models.CharField(max_length=10)
    total_buys = models.FloatField(default=0.0)
    total_buy_amount = models.FloatField(default=0.0)
    average_buy_price = models.FloatField(default=0.0)
    total_sells = models.FloatField(default=0.0)
    total_sell_amount = models.FloatField(default=0.0)
    average_sell_price = models.FloatField(default=0.0)
    profit = models.FloatField(default=0.0)
