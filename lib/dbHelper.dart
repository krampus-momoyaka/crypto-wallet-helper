
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper{




  void deleteDB(Database database){
    if(database!=null) {
      deleteDatabase(database.path);
    }
  }

  Future<Database> openDB() async {
    WidgetsFlutterBinding.ensureInitialized();
// Open the database and store the reference.
    final database = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'db.db'),
      onCreate: (db,version){
          db.execute('CREATE TABLE user_info(id	INTEGER PRIMARY KEY AUTOINCREMENT , user_name	TEXT, avatar	TEXT, wallet_address	TEXT, instagram TEXT)');
          db.execute('CREATE TABLE contacts(id	INTEGER PRIMARY KEY AUTOINCREMENT , user_name	TEXT, avatar	TEXT, wallet_address	TEXT)');
          db.execute('CREATE TABLE networks(id	INTEGER PRIMARY KEY AUTOINCREMENT , net_name	TEXT, rpc_url	TEXT, chain_id	TEXT, coin_name TEXT)');
          db.execute('CREATE TABLE transactions(id	INTEGER PRIMARY KEY AUTOINCREMENT , wallet_address_from TEXT, wallet_address_my	TEXT, direction TEXT, coin_name TEXT, net_name TEXT, amount TEXT, date TEXT, tx_hash)');
          //return db;
      },
      version: 1,
    );

    return database;
  }

}