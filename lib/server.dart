import 'dart:convert';

import 'package:http/http.dart' as http;

class Server{

  static const servBase = "http://vhost259958.cpsite.ru/api";
  static const apiKey = "0WYWXKV0ASPZQBKGM4EYRUP895MTPKIL";

  static Future<String> addUser(String pubKey, String fireToken, String instagram) async{

    final requestString = "$servBase/add_user.php";

    final body = jsonEncode(<String, dynamic>{
      "pub_key": pubKey,
      "fire_token" : fireToken,
      "login_instagram": instagram
    });

    final responce = await http.post(
      Uri.parse(requestString),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': apiKey
      },
      body: body
    );


    if(responce.statusCode == 200 && jsonDecode(responce.body)['success']){
      return "server: add_user success";
    }

    return "server: add_user error: ${responce}";

  }

  static Future<dynamic> getUser(String pubKey) async{

    final requestString = "$servBase/get_user.php?pub_key=$pubKey";

    final responce = await http.get(
        Uri.parse(requestString),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': apiKey
        },
    );

    if(responce.statusCode == 200){

      final user = jsonDecode(responce.body);
      return {'fireToken': user['fire_token'],'instagram':user['login_instagram']};

    }

    return "server: get_user error: ${responce}";

  }

  static Future<String> deleteUser(String pubKey) async{

    final requestString = "$servBase/delete_user.php?pub_key=$pubKey";

    final responce = await http.get(
      Uri.parse(requestString),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': apiKey
      },
    );

    if(responce.statusCode == 200 && responce.body == '0'){

        return "server: delete_user success";

    }

    return "server: delete_user error: ${responce}";

  }


}