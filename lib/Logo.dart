
import 'dart:collection';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:wallet_application/SendNFTPage.dart';
import 'package:wallet_application/main.dart';
import 'package:wallet_application/UserActivity.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:wallet_application/firebaseHelper.dart';
import 'package:wallet_application/server.dart';
import 'User.dart';
import 'connector.dart';
import 'constants.dart';
import 'wallet.dart';
import 'package:firebase_core/firebase_core.dart';




var isDefaultLaunch = true;


class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: FutureBuilder(
        future: _fbApp,
        builder: (context, snapshot) {

          if(snapshot.hasError){
            print(snapshot.error.toString());
            return Text("param-pam");
          }else if (snapshot.hasData){
            //FirebaseHelper.fbApp = _fbApp;
            return MyHomePage();
          }else{
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

        }
        ),
      routes: {
        '/SendNFTPage': (context) {
          if(ModalRoute.of(context)?.settings.arguments!=null) {
            final args = ModalRoute.of(context)!.settings.arguments as LinkedHashMap;
            final user = args['user'] as User;
            final data = args['message'];

            return SendNFTActivity(user: user, data: data,);
          } else return MyHomePage();
        },
        '/UserActivity': (context) {
          if(ModalRoute.of(context)?.settings.arguments!=null) {
            final args = ModalRoute.of(context)!.settings.arguments as LinkedHashMap;
            final user = args['user'] as User;
            final data = args['message'];
            return UserActivity(user: user, data: data);
          } else return MyHomePage();
          },
        '/Profile':(context) {
           return Profile();
        }
      },
    );
      // MyHomePage(),
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {

  late String? _fcmToken;
  late BuildContext mContext;

  @override
  void initState() {




    FirebaseHelper.init();
    initFB();
    initDB();



    super.initState();


    //initDB();
  }

  void initFB() async {
    _fcmToken = await FirebaseMessaging.instance.getToken();
    FirebaseHelper.fcmToken = _fcmToken;
    print('Firebase token:$_fcmToken');
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) async {
      // TODO: If necessary send token to application server.
      FirebaseHelper.fcmToken = fcmToken;
      print('Firebase token:$_fcmToken');
      if(mWallet.account!='') {
        Server.addUser(mWallet.account, fcmToken, await mWallet.getInsta()).then((value) => print(value));
      }
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    })
        .onError((err) {
          print(err.toString());
      // Error getting token.
    });
  }

  void initDB() async{


    DbHelper dbh = DbHelper();

    sqlite.Database db = await dbh.openDB();
    final user = await db.query('user_info');


    if(user.isEmpty) {

      Navigator.pushReplacement(
        mContext,
        MaterialPageRoute(builder: (context) =>  const Connector()),
              //(Route<dynamic> route) => false
      );

    }else{
      Map<String, dynamic> mapRead = user.first;
      if (mapRead['wallet_address'] != null) {
        mWallet.account = mapRead['wallet_address'];
        if(isDefaultLaunch) {
          mWallet.walletReconnect(mContext);
        }

      }
    }
    // int i = await db.rawInsert("INSERT INTO user_info (user_name,avatar,wallet_address) VALUES ('Vlad','null','null')");

    db.close();
  }

  @override
  Widget build(BuildContext context) {
    mContext = context;
    return Scaffold(
      body: Center(

        child: Column(
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

          ],
        ),
      ),
    );
  }

}