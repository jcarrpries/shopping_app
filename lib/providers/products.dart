import 'package:flutter/material.dart';
import 'package:shopping_app/models/http_exception.dart';
import 'package:shopping_app/providers/auth.dart';
import './product.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
  ];

  // var _showFavoritesOnly = false;

  final String authToken;
  final String userId;

  Products(this.authToken, this._items, this.userId);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((item) => item.isFavorite).toList();
    // }

    return [
      ..._items
    ]; //creates a copy (passing by value not reference (pass by reference is the default for dart))
    //we want to always know when items is edited so we can run notifyListeners();
  }

  List<Product> get favoriteItems {
    
    return _items.where((item) => item.isFavorite).toList();

  }

  // void showFavoritesOnly(){
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll(){
  //   _showFavoritesOnly = false;
  //   notifyListeners();

  // }

  Product findById(String id) {
    return _items.firstWhere((product) => product.id == id);
  }

  Future<void> fetchAndSetProduct([bool filterByUser = false]) async {
    final filterString = filterByUser ? '&orderBy="creatorId"&equalTo="$userId"': '';
    final url = 'https://flutter-update-469e4.firebaseio.com/products.json?auth=${authToken}$filterString';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if(extractedData == null){
        return;
      }
      
      final favoriteUrl = 'https://flutter-update-469e4.firebaseio.com/userFavorites/$userId.json?auth=${authToken}';
      final favoriteResponse = await http.get(favoriteUrl);
      final favoriteData = json.decode(favoriteResponse.body);
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          description: prodData['description'],
          title: prodData['title'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite: favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    // _items.add(value);

    final url = 'https://flutter-update-469e4.firebaseio.com/products.json?auth=${authToken}';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId':userId
        }),
      );
      final newProduct = Product(
        title: product.title,
        imageUrl: product.imageUrl,
        price: product.price,
        description: product.description,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);

      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://flutter-update-469e4.firebaseio.com/products/$id.json?auth=${authToken}';
      await http.patch(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
        }),
      );
      _items[prodIndex] = product;
      await notifyListeners();
    } else {
      print('...');
    }
  }

  void deletProduct(String id) async {
    final url = 'https://flutter-update-469e4.firebaseio.com/products/$id.json?auth=${authToken}';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];

    _items.removeAt(existingProductIndex);

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      items.insert(existingProductIndex,
          existingProduct); // optimistic updating, save a refernce to the object, deletes it then only adds it back if the delete fails
      throw HttpException('Could not delete product');
    }

    notifyListeners();
    existingProduct = null;
  }
}
