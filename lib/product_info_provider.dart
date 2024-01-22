import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mikrotik_mndp/product.dart';

class MikrotikProductInfoProvider {
  late List<MikrotikProduct> _products;

  MikrotikProductInfoProvider() {
    _products = [];
  }

  Future<List<MikrotikProduct>> loadProducts() async {
    if (_products.isNotEmpty) {
      return _products;
    }
    try {
      const String productsPath = 'assets/products.json';
      final String productsString = await rootBundle.loadString(productsPath);
      final List<dynamic> productsJson = await json.decode(productsString);
      _products = productsJson.map((e) => MikrotikProduct.fromJson(e)).toList();
      return _products;
    } catch (e) {
      return [];
    }
  }

  Future<MikrotikProduct?> find(String model) async {
    await loadProducts();
    model = model.toLowerCase().toLowerCase();
    for (var product in _products) {
      if (product.code.toLowerCase() == model) {
        return product;
      }
    }
    for (var product in _products) {
      if (product.name.toLowerCase().contains(model)) {
        return product;
      }
    }
    for (var product in _products) {
      var pP = product.code.toLowerCase().split('-');
      var mP = model.split('-');
      if (pP == mP) {
        return product;
      }
      if (pP.isEmpty || mP.isEmpty) {
        continue;
      }
      if (pP[0].contains(mP[0]) || mP.contains(pP[0])) {
        return product;
      }
    }
    return null;
  }
}
