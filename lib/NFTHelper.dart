import 'dart:convert';

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

  Asset(Map<String,dynamic> json){
    id = json['id'];
    backgroundColor = json['background_color'];

    imageUrl = json['image_url'];
    name = json['name'];


    body = json;
  }

}