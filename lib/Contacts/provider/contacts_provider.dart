

import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/User.dart';
import 'package:wallet_application/dbHelper.dart';


class ContactsProvider with ChangeNotifier {
  ContactsProvider() {
    updateContacts();
  }

  void updateContacts(){
    loadContacts().then((contacts) {
      _contacts = contacts;
      notifyListeners();
    });
  }

  List<User> _contacts = [];

  List<User> get contacts => _contacts;

  Future loadContacts() async {

    DbHelper dbh  = DbHelper();
    Database db = await dbh.openDB();

    final data = await  db.query('contacts');
    //final data = await rootBundle.loadString('assets/country_codes.json');

    //final countriesJson = json.decode(data);

    List<User> contactsList = [];

    if(data.isNotEmpty){
      data.forEach((user) {
        Map<String, dynamic> mapRead = user;

        if (mapRead['user_name'] != null) {
          User _user = User(mapRead['user_name'], mapRead['wallet_address']);
          _user.avatar = mapRead['avatar'];
          contactsList
            ..add(_user);

        }
      });
    }
    db.close();

    return contactsList;
    //
    // return countriesJson.keys.map<Country>((code) {
    //   final json = countriesJson[code];
    //   final newJson = json.addAll({'code': code.toLowerCase()});
    //
    //   return Country.fromJson(newJson);
    // }).toList()..sort(Utils.ascendingSort);
  }



}
