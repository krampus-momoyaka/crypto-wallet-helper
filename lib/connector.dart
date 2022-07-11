
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:wallet_application/dbHelper.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'constants.dart';
//import 'package:wallet_connect/wallet_connect.dart';
import 'wallet.dart';


class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;

  @override
  Future<EthereumAddress> extractAddress() {
    // TODO: implement extractAddress
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );

    return hash;
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    // TODO: implement signToSignature
    throw UnimplementedError();
  }
}


class Connector extends StatelessWidget {
  const Connector({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ConnectorPage(),
    );
  }
}

class ConnectorPage extends StatefulWidget {
  const ConnectorPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<ConnectorPage> createState() => _ConnectorPageState();

}

class _ConnectorPageState extends State<ConnectorPage> {

  late BuildContext mContext;

  @override
  void initState() {
    initDB();
    super.initState();
  }

  void initDB() async{
    DbHelper dbh = DbHelper();

    sqlite.Database db = await dbh.openDB();
    final user = await db.query('user_info');


    if(user.isEmpty) {

    }else{
      Map<String, dynamic> mapRead = user.first;
      if (mapRead['wallet_address'] != null) {
        mWallet.account = mapRead['wallet_address'];
        //mWallet.walletConnect(mContext);

      }
    }
    // int i = await db.rawInsert("INSERT INTO user_info (user_name,avatar,wallet_address) VALUES ('Vlad','null','null')");

    db.close();
  }

  @override
  Widget build(BuildContext context) {


    mContext = context;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Container(
              margin: EdgeInsets.all(20.0),
              child: SvgPicture.asset(
                "assets/svg/walletconnect-logo.svg",
                fit: BoxFit.scaleDown,
                width: 150,
                height: 150,
              ),
            ),

            const Text(
                sMainTitle,
                style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold, color: mColors.walletColor)

            ),

            Container(
              margin: const EdgeInsets.fromLTRB(0, 75, 0, 0),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Material(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  splashColor: Colors.blueGrey,
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  onTap: (){
                    //ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      mWallet.walletConnect(context);


                    //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success")));
                  },
                  child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.fromLTRB(0, 0,0, 0),
                      child: const Text("Connect",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,letterSpacing: 1,color: Colors.white),textAlign: TextAlign.center,)
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

}


