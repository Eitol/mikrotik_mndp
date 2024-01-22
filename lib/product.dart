import 'dart:convert';

class MikrotikProduct {
  final String name;
  final String code;
  final String imageUrl;
  final String productUrl;

  MikrotikProduct({
    required this.name,
    required this.code,
    required this.imageUrl,
    required this.productUrl,
  });

  factory MikrotikProduct.fromRawJson(String str) => MikrotikProduct.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MikrotikProduct.fromJson(Map<String, dynamic> json) => MikrotikProduct(
    name: json["name"],
    code: json["code"],
    imageUrl: json["image_url"],
    productUrl: json["product_url"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "code": code,
    "image_url": imageUrl,
    "product_url": productUrl,
  };
}
