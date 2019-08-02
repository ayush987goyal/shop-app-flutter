import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import './cart.dart';
import '../constants.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _items = [];
  final String authToken;

  Orders(this.authToken, this._items);

  List<OrderItem> get orders {
    return [..._items];
  }

  Future<void> fetchAndSetOrders() async {
    final url = '${Constants.API_URL}/orders.json?auth=$authToken';

    try {
      final response = await http.get(url);
      final extractedResponse =
          json.decode(response.body) as Map<String, dynamic>;

      if (extractedResponse == null) return;

      final List<OrderItem> loadedOrders = [];
      extractedResponse.forEach((orderId, orderData) {
        loadedOrders.add(OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map((cp) => CartItem(
                    id: cp['id'],
                    title: cp['title'],
                    quantity: cp['quantity'],
                    price: cp['price'],
                  ))
              .toList(),
        ));
      });

      _items = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = '${Constants.API_URL}/orders.json?auth=$authToken';
    final timeStamp = DateTime.now();

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          'products': cartProducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        }),
      );

      _items.insert(
        0,
        OrderItem(
          id: json.decode(response.body)['name'],
          amount: total,
          products: cartProducts,
          dateTime: timeStamp,
        ),
      );
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
