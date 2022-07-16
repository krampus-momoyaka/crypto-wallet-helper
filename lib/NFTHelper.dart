import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wallet_application/User.dart';


class NFT {

  static Future<List<Asset>?> getTestNFT(String address) async {
    final url = "https://testnets-api.opensea.io/api/v1/assets?owner=$address";

    final response= await http.get(Uri.parse(url));

    if(response.statusCode == 200){

      final j = json.decode(response.body);

      List<Asset> assets = [];
      for (var value in (j['assets'] as List)) {
        assets.add(Asset(value));
      };

      print(assets);

      return assets;
    }



    return null;
  }
}

class Asset{
  Map<String,dynamic>? body;
  var id = 1;
  var backgroundColor;
  String imageUrl = '';
  String name = '';
  int tokenId = 1;
  String schema = '';
  String description = '';
  String? collectionDescription = '';
  String? collectionImage = '';
  String contractAddress = '';
  String originalLink = '';

  String collectionName = '';
  Map<String,dynamic>? lastSale;
  Map<String,dynamic>? creator;
  List<Map<String,dynamic>> traits = [];

  Asset(Map<String,dynamic> json){
    id = json['id'];
    backgroundColor = json['background_color'];

    final traities = json['traits'];

    if(traities!=null&& traities is List<dynamic>){
      for (var value in traities) {
        traits.add(value as Map<String,dynamic>);
      }

    }
    imageUrl = json['image_url'];
    name = json['name'];
    tokenId = json['id'];
    description = json['description'] ?? "";
    schema =  json['asset_contract']['schema_name'];
    contractAddress = json['asset_contract']['address'];
    collectionName = json['collection']['name'];
    collectionDescription = json['collection']['description'];
    collectionImage = json['collection']['image_url'];
    lastSale = json['last_sale'];
    creator = json['creator'];
    body = json;
    originalLink = json['permalink'];






  }

}

