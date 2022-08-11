

import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/User.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:wallet_application/wallet.dart';



class Trx{
    final String direction;
    final String from;
    final String me;
    final String amount;
    final String coinName;
    final String net;
    final String date;
    final String tx;
    final String? nftName;

    Trx(this.direction, this.from, this.me, this.amount, this.coinName, this.net, this.date, this.tx, this.nftName);

}

class HistoryProvider with ChangeNotifier {
  HistoryProvider() {
    updateHistory();
  }

  void updateHistory(){
    loadHistory().then((trx) {
      _trx = trx;
      notifyListeners();
    });
  }

  List<Trx> _trx= [];

  List<Trx> get history => _trx;

  Future loadHistory() async {

    DbHelper dbh  = DbHelper();
    Database db = await dbh.openDB();

    final data = await  db.query('transactions', where: 'net_name = ?', whereArgs: [mWallet.currentNet.rpcURL]);
    //final data = await rootBundle.loadString('assets/country_codes.json');

    //final countriesJson = json.decode(data);

    List<Trx> trxList = [];

    if(data.isNotEmpty){
      data.forEach((user) {
        Map<String, dynamic> mapRead = user;

        if (mapRead['tx_hash'] != null) {
          Trx _tx = Trx(
              mapRead['direction'],
              mapRead['wallet_address_from'],
              mapRead['wallet_address_my'],
              mapRead['amount'],
              mapRead['coin_name'],
              mapRead['net_name'],
              mapRead['date'],
              mapRead['tx_hash'],
              mapRead['nft_name']
          );
          trxList
            .add(_tx);

        }
      });
    }
    db.close();

    return trxList.reversed.toList();
    //
    // return countriesJson.keys.map<Country>((code) {
    //   final json = countriesJson[code];
    //   final newJson = json.addAll({'code': code.toLowerCase()});
    //
    //   return Country.fromJson(newJson);
    // }).toList()..sort(Utils.ascendingSort);
  }



}
