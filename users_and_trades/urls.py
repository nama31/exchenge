# # users_and_trades/urls.py
# from django.urls import path
# from . import views

# urlpatterns = [
#     path('register/', views.register, name='register'),  # Регистрация пользователей
#     path('sign-in/', views.sign_in, name='sign_in'),  # Авторизация
#     path('users/', views.get_users, name='users'),  # Получение списка пользователей
#     path('transactions/add/', views.add_transaction, name='add_transaction'),
#     path('transactions/', views.get_transactions, name='get_transactions'),
#     path('currencies/', views.get_currencies, name='get_currencies'),
#     path('currencies/add/', views.add_currency, name='add_currency'),
#     path('currencies/delete/<str:currency_name>/', views.delete_currency, name='delete_currency'),
#     path('users/delete/<int:user_id>/', views.delete_user, name='delete_user'),
#     path('transactions/delete/<int:transaction_id>/', views.delete_transaction, name='delete_transaction'),
#     path('reports', views.get_reports, name='get_reports'),
#     path('delete_report', views.delete_report, name='delete_report'),  # Без слэша в конце
#     path('clear/', views.clear_history_and_reports, name='clear_history_and_reports'),
# ]


