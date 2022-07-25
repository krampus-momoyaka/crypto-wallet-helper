import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/NFTHelper.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/firebaseHelper.dart';
import 'package:wallet_application/server.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet_application/wallet.dart';
import 'package:http/http.dart' as http;
import 'User.dart';
import 'dbHelper.dart';
import 'network.dart';


class OperationsActivity extends StatelessWidget {
  const OperationsActivity( {Key? key, required this.user, this.data, this.isSend = true}) : super(key: key);
  final User user;
  final Map<String, dynamic>? data;
  final bool isSend;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OperationsActivityPage( user: user, data: data, isSend: isSend);
  }
}



class OperationsActivityPage extends StatefulWidget {
  const OperationsActivityPage( {Key? key, required this.user, this.data, required this.isSend}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  final User user;
  final Map<String, dynamic>? data;
  final bool isSend;
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<OperationsActivityPage> createState() => _OperationsActivityPageState();

}

class _OperationsActivityPageState extends State<OperationsActivityPage> {
  late User user;

  late Map<String,dynamic> data;
  dynamic userInfo = "";
  String userFcmToken = "";

  Image? image;

  // var colorText = Colors.black;

  TextEditingController userNameController = TextEditingController();


  var isPublic = false;
  var receiveEnabled = false;

  var sendEnabled = false;

  double amount = 0;
  String initialAmount = '0.0';


  @override
  void initState() {
    super.initState();
    user = widget.user;


    if(widget.data!=null) {
      data = widget.data!;

      initialAmount = data['amount'];


    }


    if(mWallet.provider==null) {
      mWallet.walletReconnect(context).then((value) => setState((){

      }));
    }



    Future.sync(() async {
      await _initDB();
      userInfo = await Server.getUser(user.pubKey);
      if(userInfo!=""){
        userFcmToken = userInfo['fireToken'];
        setState(() {

          if(mWallet.currentNet == mNetworks.unknownNet){
            sendEnabled = false;
            receiveEnabled = false;
          }else {
            receiveEnabled = true;
          }
        });
      }


    });


    mWallet.updateCallback = (){
      setState(() {
        if(mWallet.currentNet == mNetworks.unknownNet){
          sendEnabled = false;
          receiveEnabled = true;
        }else {
          sendEnabled = true;

          if(userFcmToken!=''){
            receiveEnabled = true;
          }
        }
      });
    };
  }


  _initDB() async {
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();


    final c = await db.query('contacts', where: "wallet_address = '${user.pubKey}'");

    if (c.isNotEmpty) {
      Map<String, dynamic> mapRead = c.first;
      setState(() {
        if (mapRead['user_name'] != null) {
          user.name = mapRead['user_name'];
          user.avatar = mapRead['avatar'];
          userNameController.text = user.name;
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        centerTitle: true,
        title: Text(""),

        backgroundColor: mColors.light,
        foregroundColor: Colors.black,
        elevation: 1,

      ),
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return Text("123");

          }
      ),
    );
  }



  Future<String> getMyName()async{

    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();

    String userName = "User";

    final user = await db.query('user_info');
    if(!user.isEmpty) {
      Map<String, dynamic> mapRead = user.first;
      setState(() {
        if (mapRead['user_name'] != null) {
          userName = mapRead['user_name'];
          //imagePath = mapRead['avatar'];
        }
      });

    }

    db.close();

    return userName;
  }






  void notifyReceiver(String tx) async {
    var name = await getMyName();


    final token = await FirebaseHelper.getBearerToken();
    print(token);
    var responce = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/walletapp-5d95f/messages:send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        "message": {
          "token":userFcmToken,
          "data": {
            "message": "You received Transaction",
            "amount": amount.toString(),
            "currency": mWallet.currentNet.coinName,
            "net": mWallet.currentNet.rpcURL,
            "name": name,
            "pubKey": mWallet.account.toLowerCase(),
            "to":user.pubKey,
            "tx":tx,
          },
          "notification":{
            "title":"You received Transaction from $name (${mWallet.account.toString().substring(0,7)})",
            "body":"$amount ${mWallet.currentNet.coinName}"
          },
        },


      }),
    );



    mWallet.writeTransactionToHistory(
        direction: "outcome",
        net: mWallet.currentNet.rpcURL,
        from: user.pubKey,
        me: mWallet.account.toLowerCase(),
        coinName: mWallet.currentNet.coinName,
        txHash: tx,
        amount: amount.toString()

    );

  }


  void requestTransaction() async {
    var name = await getMyName();
    final token = await FirebaseHelper.getBearerToken();
    print(token);
    if (userFcmToken != "null"){

      var responce = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/walletapp-5d95f/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':'Bearer $token'
        },
        body: jsonEncode(<String, dynamic>{
          "message": {
            "token":userFcmToken,
            "data": {
              "message": "Transaction request",
              "amount": amount.toString(),
              "currency": mWallet.currentNet.coinName,
              "net": mWallet.currentNet.rpcURL,
              "name": name,
              "pubKey": mWallet.account.toLowerCase(),
              "chain_id":mWallet.currentNet.chainID
            },
            "notification":{
              "title":"Transaction request from $name (${mWallet.account.toString().substring(0,7)})",
              "body":"$amount ${mWallet.currentNet.coinName}"
            },
          },


        }),
      );
      var i = 0;

      if(responce.statusCode == 200){
        showToast("Request sent",context: context);
      }else{
        showToast("Something went wrong. Try again!",context: context);
      }
    }



  }


}



