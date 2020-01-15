import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/models/http_exception.dart';

class Product with ChangeNotifier {
  final String id, title, description, imageUrl;
  final double price;
  bool isFavorite;

  Future<void> toggleFavortieStatus(String authToken, userId) async {
    var oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();

    final url = 'https://flutter-update-469e4.firebaseio.com/userFavorites/$userId/$id.json?auth=${authToken}';

    try {
      final response = await http.put(
        url,
        body: json.encode(
          isFavorite,
        ),
      );
      if (response.statusCode >= 400) {
        throw HttpException('Favorite Message Not stored');
      }
    } catch (error) {
      isFavorite = oldStatus;
      notifyListeners();
    } finally {
      oldStatus = null;
    }
  }

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.imageUrl,
    @required this.price,
    this.isFavorite = false,
  });
}
