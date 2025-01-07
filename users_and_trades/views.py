
# Create your views here.
from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate
from .forms import CustomUserCreationForm
# users_and_trades/views.py
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from django.contrib.auth.models import User  # Убедитесь, что импорт User есть

from django.shortcuts import get_object_or_404
from .models import Trade, Currency,CurrencyReport  # Убедитесь, что эти модели определены

from django.core.paginator import Paginator
from django.views.decorators.http import require_http_methods




@csrf_exempt
def sign_in(request):
    if request.method == 'GET':
        user_id = request.GET.get('user_id')
        password = request.GET.get('password')

        if user_id and password:
            # Аутентификация пользователя
            user = authenticate(username=user_id, password=password)

            if user is not None:  # Исправлено условие
                return JsonResponse({'message': 'Login successful'}, status=200)
            else:
                return JsonResponse({'message': 'Invalid credentials'}, status=400)
        else:
            return JsonResponse({'message': 'Missing data'}, status=400)

    else:
        return JsonResponse({'message': 'Invalid method'}, status=405)


@csrf_exempt
def get_users(request):
    page = request.GET.get('page', 1)
    page_size = request.GET.get('page_size', 10)  # Количество пользователей на страницу
    users = User.objects.all()
    paginator = Paginator(users, page_size)
    try:
        paginated_users = paginator.page(page)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)

    data = {
        'users': list(paginated_users.object_list.values()),  # Конвертация объектов в словари
        'total_pages': paginator.num_pages,
        'current_page': paginated_users.number,
    }
    return JsonResponse(data)


@csrf_exempt
@require_http_methods(["DELETE"])
def delete_user(request, user_id):
    try:
        # Пытаемся найти пользователя по ID
        user = User.objects.get(id=user_id)
        user.delete()  # Удаляем пользователя
        return JsonResponse({'message': 'User deleted successfully'}, status=200)
    except User.DoesNotExist:
        return JsonResponse({'message': 'User not found'}, status=404)




@csrf_exempt
def register(request):
    if request.method == 'GET':  # Проверяем метод запроса
        user_id = request.GET.get('user_id')  # Получаем user_id из параметров GET
        password = request.GET.get('password')  # Получаем password из параметров GET

        if user_id and password:  # Проверяем, что оба параметра переданы
            # Проверяем, существует ли уже пользователь с таким именем
            if User.objects.filter(username=user_id).exists():
                return JsonResponse({'message': 'User already exists'}, status=400)

            # Создаем нового пользователя
            User.objects.create_user(username=user_id, password=password)
            return JsonResponse({'message': 'Registration successful'}, status=200)
        else:
            return JsonResponse({'message': 'Missing data'}, status=400)
    else:
        return JsonResponse({'message': 'Invalid method'}, status=405)



@csrf_exempt
def add_transaction(request):
    if request.method == 'GET':
        try:
            # Получаем параметры из GET-запроса
            currency = request.GET.get('currency')
            amount = float(request.GET.get('amount', 0))
            price = float(request.GET.get('price', 0))
            total = float(request.GET.get('total', 0))
            transaction_type = request.GET.get('type')  # 'Buy' или 'Sell'

            # Проверяем, что все необходимые поля переданы
            if not all([currency, amount, price, total, transaction_type]):
                return JsonResponse({'error': 'Missing required fields'}, status=400)

            # Сохраняем данные в модель Transaction
            transaction = Trade(
                currency=currency,
                amount=amount,
                price=price,
                total=total,
                type=transaction_type,
            )
            transaction.save()

            # Обновляем данные в CurrencyReport
            report, created = CurrencyReport.objects.get_or_create(currency=currency)

            if transaction_type == 'Buy':
                # Обновление данных для покупок
                total_buy_amount = report.total_buy_amount + amount
                average_buy_price = ((report.average_buy_price * report.total_buy_amount) + (price * amount)) / total_buy_amount
                report.total_buys += total
                report.total_buy_amount = total_buy_amount
                report.average_buy_price = average_buy_price
            elif transaction_type == 'Sell':
                # Обновление данных для продаж
                total_sell_amount = report.total_sell_amount + amount
                average_sell_price = ((report.average_sell_price * report.total_sell_amount) + (price * amount)) / total_sell_amount
                report.total_sells += total
                report.total_sell_amount = total_sell_amount
                report.average_sell_price = average_sell_price

                # Расчет профита
                report.profit += amount * (report.average_sell_price - report.average_buy_price)

            report.save()

            return JsonResponse({'message': 'Transaction added successfully', 'id': transaction.id}, status=200)

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)

    # Если запрос не GET, возвращаем ошибку
    return JsonResponse({'message': 'Invalid method'}, status=405)


@csrf_exempt
def get_transactions(request):
    if request.method == 'GET':
        transactions = Trade.objects.all().values(
    'id', 'currency', 'amount', 'price', 'total', 'type', 'created_at'
    )
        return JsonResponse({'transactions': list(transactions)}, status=200)
    else:
        return JsonResponse({'message': 'Invalid method'}, status=405)



@csrf_exempt
def get_currencies(request):
    if request.method == 'GET':
        # Извлекаем имя, цену покупки и цену продажи
        currencies = Currency.objects.all().values('name', 'buy_price', 'sell_price')
        currencies_data = list(currencies)  # Преобразуем QuerySet в список
        return JsonResponse({'currencies': currencies_data}, status=200)
    else:
        return JsonResponse({'message': 'Invalid method'}, status=405)




@csrf_exempt
def add_currency(request):
    if request.method == 'GET':  # Метод GET
        try:
            # Получаем параметры из строки запроса
            name = request.GET.get('currency')
            buy_price = request.GET.get('buy_price')  # Цена покупки
            sell_price = request.GET.get('sell_price')  # Цена продажи

            # Проверяем, что все поля заполнены
            if not name or not buy_price or not sell_price:
                return JsonResponse({'error': 'Missing required fields'}, status=400)

            # Преобразуем цены в числа и создаём новую валюту
            currency = Currency.objects.create(
                name=name,
                buy_price=float(buy_price),
                sell_price=float(sell_price)
            )

            # Успешный ответ
            return JsonResponse({'message': 'Currency added successfully'}, status=201)
        except Exception as e:
            # Обработка возможных ошибок
            return JsonResponse({'error': str(e)}, status=400)
    else:
        # Если метод запроса не GET
        return JsonResponse({'message': 'Invalid method'}, status=405)


@csrf_exempt
@require_http_methods(["DELETE"])
def delete_currency(request, currency_name):
    try:
        # Пытаемся найти валюту по имени
        currency = Currency.objects.get(name=currency_name)
        currency.delete()  # Удаляем валюту
        return JsonResponse({'message': 'Currency deleted successfully'}, status=200)
    except Currency.DoesNotExist:
        return JsonResponse({'message': 'Currency not found'}, status=404)


@csrf_exempt
def delete_transaction(request, transaction_id):
    if request.method == 'DELETE':
        try:
            # Try to fetch the transaction by ID
            transaction = Trade.objects.get(id=transaction_id)
            transaction.delete()

            return JsonResponse({'message': 'Transaction deleted successfully'}, status=200)
        except Trade.DoesNotExist:
            return JsonResponse({'error': 'Transaction not found'}, status=404)
    else:
        return JsonResponse({'message': 'Invalid method'}, status=405)

@csrf_exempt
def get_reports(request):
    if request.method == 'GET':
        try:
            reports = CurrencyReport.objects.all()
            data = [
                {
                    'currency': report.currency,
                    'total_buys': report.total_buys,
                    'average_buy_price': report.average_buy_price,
                    'total_sells': report.total_sells,
                    'average_sell_price': report.average_sell_price,
                    'profit': report.profit,
                }
                for report in reports
            ]
            return JsonResponse({'reports': data}, status=200)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)

    return JsonResponse({'message': 'Invalid method'}, status=405)



@csrf_exempt
def delete_report(request):
    if request.method == 'DELETE':
        try:
            # Получаем название валюты или идентификатор из запроса
            currency = request.GET.get('currency', None)

            if not currency:
                return JsonResponse({'error': 'Currency parameter is required'}, status=400)

            # Находим запись в базе данных
            report = CurrencyReport.objects.filter(currency=currency).first()

            if not report:
                return JsonResponse({'error': 'Report not found'}, status=404)

            # Удаляем запись
            report.delete()
            return JsonResponse({'message': f'Report for currency "{currency}" deleted successfully'}, status=200)

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)

    return JsonResponse({'message': 'Invalid method'}, status=405)


@csrf_exempt
@require_http_methods(["DELETE"])
def clear_history_and_reports(request):
    try:
        # Удаляем все записи из модели Trade
        Trade.objects.all().delete()

        # Удаляем все записи из модели CurrencyReport
        CurrencyReport.objects.all().delete()

        return JsonResponse({'message': 'History and reports cleared successfully'}, status=200)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)

