import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

class User {
  String name;
  final String pubKey;

  User(this.name, this.pubKey);

  String avatar = "null";

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        pubKey = json['pubKey'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'pubKey': pubKey,
  };
}