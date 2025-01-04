import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SignInPage(),
        '/trading': (context) => TradingPage(),
        '/history': (context) => HistoryPage(),
        '/currency': (context) => CurrencyPage(),
        '/users': (context) => UsersTablePage(),
        '/signUp': (context) => SignUpPage(),
        '/kassa': (context) => KassaPage(),
        '/clear': (context) => ClearHistoryDialog(),


      },
    );
  }
}


class SignInPage extends StatelessWidget {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Функция для связи с сервером
  void signIn(BuildContext context) async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/sign-in/'); // Убедитесь, что URL правильный

    try {
      final response = await http.get(
        url.replace(queryParameters: {
          'user_id': userIdController.text,
          'password': passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        Navigator.pushNamed(context, '/trading');
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка соединения с сервером')),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Enter your user ID and password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30.0),
              TextField(
                controller: userIdController,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () => signIn(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TradingPage extends StatefulWidget {
  @override
  _TradingPageState createState() => _TradingPageState();
}


class _TradingPageState extends State<TradingPage> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  String selectedCurrency = 'USD';
  String selectedPriceType = 'Buy'; // Тип цены: 'Buy' или 'Sell'
  Map<String, Map<String, double>> currencies = {};

  // Метод для загрузки валют с сервера
  Future<void> loadCurrencies() async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/currencies/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Преобразуем список в Map с покупкой и продажей
        List<dynamic> currencyList = data['currencies'];
        Map<String, Map<String, double>> newCurrencies = {};

        for (var item in currencyList) {
          String currencyName = item['name'];
          double buyPrice = double.tryParse(item['buy_price'].toString()) ?? 0.0;
          double sellPrice = double.tryParse(item['sell_price'].toString()) ?? 0.0;

          newCurrencies[currencyName] = {
            'Buy': buyPrice,
            'Sell': sellPrice,
          };
        }

        setState(() {
          currencies = newCurrencies;
          if (currencies.containsKey(selectedCurrency)) {
            priceController.text = currencies[selectedCurrency]![selectedPriceType].toString();
          }
        });
      } else {
        print('Failed to load currencies');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  // Функция для обновления поля Total
  void _updateTotal() {
    final price = currencies[selectedCurrency]?[selectedPriceType] ?? 0.0;
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final total = price * amount;
    totalController.text = total.toStringAsFixed(2); // Форматируем до 2 знаков после запятой
  }

  @override
  void initState() {
    super.initState();
    loadCurrencies();
  }

  // Метод для отправки транзакции на сервер через GET
  void saveTransaction(BuildContext context, String type) async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/transactions/add/');

    final urlWithParams = Uri.https(
      url.authority,
      url.path,
      {
        'currency': selectedCurrency,
        'amount': amountController.text,
        'price': priceController.text,
        'total': totalController.text,
        'type': type,
      },
    );

    try {
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved!')),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['error']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading Page'),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            if (value == 'History') {
              Navigator.pushNamed(context, '/history');
            } else if (value == 'Currency') {
              Navigator.pushNamed(context, '/currency');
            } else if (value == 'Users') {
              Navigator.pushNamed(context, '/users');
            } else if (value == 'Kassa') {
              Navigator.pushNamed(context, '/kassa');
            }
            else if (value == 'Clear') {
              Navigator.pushNamed(context, '/clear');
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'History',
              child: Text('History'),
            ),
            const PopupMenuItem<String>(
              value: 'Currency',
              child: Text('Currency'),
            ),
            const PopupMenuItem<String>(
              value: 'Users',
              child: Text('Users'),
            ),
            const PopupMenuItem<String>(
              value: 'Kassa',
              child: Text('Kassa'),
            ),
            const PopupMenuItem<String>(
              value: 'Clear',
              child: Text('Clear'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                value: selectedCurrency,
                items: currencies.keys
                    .map((currency) => DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCurrency = value!;
                    priceController.text =
                        currencies[selectedCurrency]?[selectedPriceType].toString() ?? '';
                    _updateTotal(); // Обновляем total при изменении валюты
                  });
                },
                onTap: () async {
                  await loadCurrencies(); // Обновляем список валют при открытии
                },
              ),
              const SizedBox(height: 15.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                value: selectedPriceType,
                items: ['Buy', 'Sell']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriceType = value!;
                    priceController.text =
                        currencies[selectedCurrency]?[selectedPriceType].toString() ?? '';
                    _updateTotal(); // Обновляем total при изменении типа цены
                  });
                },
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                enabled: false,
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  _updateTotal(); // Пересчитываем total при изменении суммы
                },
              ),
              const SizedBox(height: 15.0),
              TextField(
                controller: totalController,
                decoration: InputDecoration(
                  labelText: 'Total',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                enabled: false,
              ),
              const SizedBox(height: 30.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      saveTransaction(context, 'Sell');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Sell',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      saveTransaction(context, 'Buy');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}








class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/transactions/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          transactions = List<Map<String, dynamic>>.from(json.decode(response.body)['transactions']);
        });
      } else {
        print('Failed to load transactions');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _deleteTransaction(int id) async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/transactions/delete/$id/');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          transactions.removeWhere((transaction) => transaction['id'] == id);
        });
        print('Transaction deleted successfully');
      } else {
        print('Failed to delete transaction');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, // Добавляем вертикальную прокрутку
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Горизонтальная прокрутка для DataTable
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Currency')), // Новый столбец для валюты
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Actions')),
            ],
            rows: transactions
                .map(
                  (transaction) => DataRow(
                cells: [
                  DataCell(Text(transaction['created_at'])),
                  DataCell(Text(transaction['currency'] ?? 'N/A')), // Вывод валюты
                  DataCell(Text(transaction['type'])),
                  DataCell(Text(transaction['amount'])),
                  DataCell(Text(transaction['price'])),
                  DataCell(Text(transaction['total'])),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteTransaction(transaction['id']),
                    ),
                  ),
                ],
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}









class CurrencyPage extends StatefulWidget {
  @override
  _CurrencyPageState createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController buyPriceController = TextEditingController();
  final TextEditingController sellPriceController = TextEditingController();
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = false;

  // Метод для получения списка валют с сервера
  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    final url = 'https://kent2.pythonanywhere.com/currencies/';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['currencies'];
        setState(() {
          _currencies = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Не удалось загрузить валюты');
      }
    } catch (error) {
      print('Ошибка загрузки валют: $error');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки валют: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Метод добавления валюты
  Future<void> addCurrency() async {
    final url = Uri.parse('https://kent2.pythonanywhere.com/currencies/add/');

    if (currencyController.text.isEmpty ||
        buyPriceController.text.isEmpty ||
        sellPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    final urlWithParams = Uri.https(
      url.authority,
      url.path,
      {
        'currency': currencyController.text,
        'buy_price': buyPriceController.text,
        'sell_price': sellPriceController.text,
      },
    );

    try {
      final response = await http.get(urlWithParams);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Валюта успешно добавлена!')),
        );

        // Очистка полей ввода
        currencyController.clear();
        buyPriceController.clear();
        sellPriceController.clear();

        // Обновить список валют
        await _fetchCurrencies();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Ошибка: ${errorData['error']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Ошибка: $error')),
      );
    }
  }

  // Метод удаления валюты
  Future<void> _deleteCurrency(String currencyName) async {
    final url = 'https://kent2.pythonanywhere.com/currencies/delete/$currencyName/';

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _currencies.removeWhere((currency) => currency['name'] == currencyName);
        });
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Валюта успешно удалена!')),
        );
      } else {
        throw Exception('Не удалось удалить валюту');
      }
    } catch (error) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Currency Manager', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добавить валюту',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: currencyController,
              decoration: InputDecoration(
                labelText: 'Название валюты',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: buyPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Цена покупки',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: sellPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Цена продажи',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addCurrency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Добавить',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 40),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  return ListTile(
                    title: Text(currency['name']),
                    subtitle: Text(
                        'Цена покупки: ${currency['buy_price']}, Цена продажи: ${currency['sell_price']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () =>
                          _deleteCurrency(currency['name']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}











class UsersTablePage extends StatelessWidget {
  const UsersTablePage({super.key});

  static const int rowsPerPage = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Users', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const PaginationWidget(rowsPerPage: rowsPerPage),
    );
  }
}

class PaginationWidget extends StatefulWidget {
  final int rowsPerPage;

  const PaginationWidget({
    super.key,
    required this.rowsPerPage,
  });

  @override
  State<PaginationWidget> createState() => _PaginationWidgetState();
}

class _PaginationWidgetState extends State<PaginationWidget> {
  int _currentPage = 0;
  bool _isLoading = false;
  List<List<String>> _data = [];
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    // Используем addPostFrameCallback для безопасного доступа к context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://kent2.pythonanywhere.com/users?page=${_currentPage + 1}&page_size=${widget.rowsPerPage}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        setState(() {
          if (jsonData.containsKey('users') && jsonData['users'] is List) {
            _data = (jsonData['users'] as List)
                .map((user) {
              if (user is Map<String, dynamic>) {
                final username = user['username']?.toString() ?? 'N/A';
                final email = user['email']?.toString() ?? 'N/A';
                final phone = 'N/A';  // Пример, если в ответе нет телефона
                final balance = 'N/A'; // Пример, если в ответе нет баланса
                return [username, email, phone, balance, user['id'].toString()];  // Преобразуем ID в строку
              }
              return ['N/A', 'N/A', 'N/A', 'N/A', -1];
            })
                .toList()
                .cast<List<String>>(); // Приведение к List<List<String> с ID
          } else {
            _data = [];
          }

          if (jsonData.containsKey('total_pages')) {
            _totalPages = jsonData['total_pages'] is int ? jsonData['total_pages'] : 1;
          } else {
            _totalPages = 1;
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error fetching users: $error');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error fetching users: $error')),

      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    final url = 'https://kent2.pythonanywhere.com/users/delete/$userId/';
    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _data.removeWhere((row) => row[4] == userId.toString()); // Удаляем пользователя по ID
        });
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('User deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Failed to delete user')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error deleting user: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('User name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _data
                  .map(
                    (row) => DataRow(
                  cells: row
                      .sublist(0, 4)  // Заполняем все колонки, кроме последней
                      .map(
                        (cell) => DataCell(Text(cell)),
                  )
                      .toList()
                    ..add(
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            int userId = int.parse(row[4].toString());
                            _deleteUser(userId);  // Вызываем функцию удаления
                          },
                        ),
                      ),
                    ),
                ),
              )
                  .toList(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentPage > 0
                  ? () {
                setState(() {
                  _currentPage--;
                });
                _fetchUsers();
              }
                  : null,
              icon: const Icon(Icons.arrow_back),
            ),
            Text('Page ${_currentPage + 1} of $_totalPages'),
            IconButton(
              onPressed: _currentPage < _totalPages - 1
                  ? () {
                setState(() {
                  _currentPage++;
                });
                _fetchUsers();
              }
                  : null,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signUp');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              minimumSize: const Size(150, 50),
            ),
            child: const Text(
              'New',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}





class SignUpPage extends StatelessWidget {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signUp(BuildContext context) async {
    final url = Uri.parse(
      'https://kent2.pythonanywhere.com/register/',
    ); // Убедитесь, что URL правильный

    try {
      // Создаем Uri с параметрами
      final urlWithParams = Uri.https(
        url.authority,
        url.path,
        {
          'user_id': userIdController.text,
          'password': passwordController.text,
        },
      );

      // Выполняем GET-запрос
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        Navigator.pop(context); // Возврат к предыдущей странице
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка соединения с сервером')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sign up', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'user ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                signUp(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(150, 50),
              ),
              child: const Text(
                'ADD',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






class KassaPage extends StatelessWidget {
  const KassaPage({super.key});

  static const int rowsPerPage = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Kassa', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: KassaPaginationWidget(rowsPerPage: rowsPerPage),
    );
  }
}

class KassaPaginationWidget extends StatefulWidget {
  final int rowsPerPage;

  const KassaPaginationWidget({
    super.key,
    required this.rowsPerPage,
  });

  @override
  State<KassaPaginationWidget> createState() => _KassaPaginationWidgetState();
}

class _KassaPaginationWidgetState extends State<KassaPaginationWidget> {
  int _currentPage = 0;
  List<List<String>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Загружаем данные при инициализации
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('https://kent2.pythonanywhere.com/reports/'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body)['reports'];
        setState(() {
          _data = jsonData
              .map((report) => [
            report['currency'].toString(),
            report['total_buys'].toString(),
            report['average_buy_price'].toString(),
            report['total_sells'].toString(),
            report['average_sell_price'].toString(),
            report['profit'].toString(),
          ])
              .toList()
              .cast<List<String>>(); // Явно приводим к типу List<List<String>?>
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Функция для удаления отчета о валюте
  Future<void> _deleteReport(String currency) async {
    try {
      final response = await http.delete(
        Uri.parse('http://kent2.pythonanywhere.com/delete_report?currency=$currency'),
      );

      if (response.statusCode == 200) {
        // Успешно удалено, обновляем данные
        setState(() {
          _data.removeWhere((row) => row[0] == currency);
        });
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('Currency report deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPages = (_data.length / widget.rowsPerPage).ceil();
    final int startRow = _currentPage * widget.rowsPerPage;
    final int endRow = (startRow + widget.rowsPerPage > _data.length)
        ? _data.length
        : startRow + widget.rowsPerPage;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Currency')),
                  DataColumn(label: Text('Buy')),
                  DataColumn(label: Text('Buy Avg')),
                  DataColumn(label: Text('Sell')),
                  DataColumn(label: Text('Sell Avg')),
                  DataColumn(label: Text('Profit')),
                  DataColumn(label: Text('Actions')), // Новый столбец для действий
                ],
                rows: _data
                    .sublist(startRow, endRow)
                    .map(
                      (row) => DataRow(
                    cells: [
                      ...row.map((cell) => DataCell(Text(cell))).toList(),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final currency = row[0]; // Предполагаем, что первая колонка - это currency
                            await _deleteReport(currency); // Удаление валюты
                          },
                        ),
                      ),
                    ],
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentPage > 0
                  ? () {
                setState(() {
                  _currentPage--;
                });
              }
                  : null,
              icon: const Icon(Icons.arrow_back),
            ),
            Text('Page ${_currentPage + 1} of $totalPages'),
            IconButton(
              onPressed: _currentPage < totalPages - 1
                  ? () {
                setState(() {
                  _currentPage++;
                });
              }
                  : null,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}



class ClearHistoryDialog extends StatelessWidget {
  const ClearHistoryDialog({Key? key}) : super(key: key);

  Future<void> clearHistory(BuildContext context) async {
    const String url = 'https://kent2.pythonanywhere.com/clear/';
    try {
      final response = await http.delete(Uri.parse(url)); // Используем метод DELETE
      if (response.statusCode == 200) {
        debugPrint('History and reports cleared successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History and reports cleared successfully.'),
          ),
        );
      } else {
        debugPrint('Failed to clear history: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear history: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Deletion'),
      content: const Text(
        'Are you sure you want to delete all history and reports? This action cannot be undone.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Закрыть диалог
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Закрыть диалог
            clearHistory(context); // Вызвать функцию удаления данных
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

// Как вызывать этот диалог
void showClearHistoryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const ClearHistoryDialog();
    },
  );
}






