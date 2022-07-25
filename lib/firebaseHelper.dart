import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/Logo.dart';
import 'package:wallet_application/main.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:wallet_application/wallet.dart';
import 'User.dart';


class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}


class FirebaseHelper{
  static String? fcmToken;

  static FirebaseApp? fbApp;

  static final messaging = FirebaseMessaging.instance;


  static late NotificationSettings settings;


  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static String notificationData = "";




  String? selectedNotificationPayload;


  static void init() async {
     settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );


     // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
     //   print("onMessage: $message");
     //   FirebaseHelper.notificationData = message.data['message'].toString();
     //   notificationCallback();
     // });
     // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
     //   print("onMessageOpenedApp: $message");
     //
     //   FirebaseHelper.notificationData = message.data['message'].toString();
     //
     //   setState(() {
     //     showToast(message.data['message'].toString(),context: context);
     //   });
     // });


     FirebaseMessaging.instance.getInitialMessage().then((message) async {
       if (message != null) {

         if (message.data['message']=='Transaction request') {
           print('terminate message opened app: '+message.data['message']);
           print('terminate message data:' + jsonEncode(message.data));


           isDefaultLaunch = false;

           mWallet.walletConnect(null).then(
                   (value){
                     navigatorKey.currentState?.pushNamed('/UserActivity', arguments: {
                       'user':User(message.data['name'], message.data['pubKey']),
                       'message': message.data
                     }).then((value){
                        navigatorKey.currentState?.pushNamed('/Profile');
                     });
                   }
           );
         }

         if(message.data['message']=='You received Transaction'){
           print('terminate message opened app: '+message.data['message']);
           print('terminate message data:' + jsonEncode(message.data));


           isDefaultLaunch = true;
           // mWallet.writeTransactionToHistory(
           //     direction: 'income',
           //     from:message.data['pubKey'] ,
           //     me:message.data['to'] ,
           //     net: message.data['net'],
           //     coinName:message.data['currency'],
           //     amount: message.data['amount'],
           //     txHash: message.data['tx'],
           // );
         }
       }
     });


     AndroidNotificationDetails _androidNotificationDetails =
     AndroidNotificationDetails(
       'channel ID',
       'channel name',
       channelDescription :'channel description',
       playSound: true,
       priority: Priority.high,
       importance: Importance.high,
     );

     IOSNotificationDetails _iosNotificationDetails = IOSNotificationDetails(
         presentAlert: null,
         presentBadge: null,
         presentSound: null,
         badgeNumber: null,
         attachments: null,
         subtitle: null,
         threadIdentifier: null
     );

     NotificationDetails platformChannelSpecifics =
     NotificationDetails(
         android: _androidNotificationDetails,
         iOS: _iosNotificationDetails);

     const AndroidInitializationSettings initializationSettingsAndroid =
     AndroidInitializationSettings("launch_background");

     /// Note: permissions aren't requested here just to demonstrate that can be
     /// done later
     final IOSInitializationSettings initializationSettingsIOS =
     IOSInitializationSettings(
         requestAlertPermission: false,
         requestBadgePermission: false,
         requestSoundPermission: false,
         onDidReceiveLocalNotification: null,
     );

     final InitializationSettings initializationSettings = InitializationSettings(
       android: initializationSettingsAndroid,
       iOS: initializationSettingsIOS,
     );
     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
         onSelectNotification: (String? payload) async {
           if (payload != null) {
             print('notification payload: $payload');


             if (payload != '') {
               final message = jsonDecode(payload);

               switch(message['message']){
                 case 'Transaction request': navigatorKey.currentState?.pushNamed('/UserActivity',
                     arguments: {'user':User(message['name'], message['pubKey']), 'message':message}); break;
                 case 'NFT request': navigatorKey.currentState?.pushNamed('/SendNFTPage',
                     arguments: {'user':User(message['name'], message['pubKey']), 'message':message}); break;

               }
             }
           }
           //selectedNotificationPayload = payload;
           //selectNotificationSubject.add(payload);
         });

     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
       print('Got a message whilst in the foreground!');
       print('Message data: ${message.data}');


       String mes = message.data['message'];


       notificationData = mes;

       switch(mes){

         case "You received Transaction":
           String name = await getUsernameByPubKey(message.data['pubKey'].toString());
           name == 'User' ? name = message.data['name']: name = name;
           String title = mes + " from " + name + " (${message.data['pubKey'].toString().substring(0,7)})";
           String body =  message.data['amount'].toString() + " " + message.data['currency'];


           mWallet.writeTransactionToHistory(
             direction: 'income',
             from:message.data['pubKey'] ,
             me:message.data['to'] ,
             net: message.data['net'],
             coinName:message.data['currency'],
             amount: message.data['amount'],
             txHash: message.data['tx'],
           );


           await flutterLocalNotificationsPlugin.show(
             0,
             title,
             body,
             platformChannelSpecifics,
             payload: '',
           );


           break;

         case "Transaction request":
           String name = await getUsernameByPubKey(message.data['pubKey'].toString());
           name == 'User' ? name = message.data['name']: name = name;
           String title = mes + " from " + name + " (${message.data['pubKey'].toString().substring(0,7)})";
           String body =  message.data['amount'].toString() + " " + message.data['currency'];




           await flutterLocalNotificationsPlugin.show(
             0,
             title,
             body,
             platformChannelSpecifics,
             payload: jsonEncode(message.data),
           );


           break;
         case "NFT request":
           String name = await getUsernameByPubKey(message.data['pubKey'].toString());
           name == 'User' ? name = message.data['name']: name = name;
           String title = mes + " from " + name + " (${message.data['pubKey'].toString().substring(0,7)})";
           String body =  message.data['token_name'].toString();

           await flutterLocalNotificationsPlugin.show(
             0,
             title,
             body,
             platformChannelSpecifics,
             payload: jsonEncode(message.data),
           );


           break;
         case 'You received NFT':
           String name = await getUsernameByPubKey(message.data['pubKey'].toString());
           name == 'User' ? name = message.data['name']: name = name;
           String title = mes + " from " + name + " (${message.data['pubKey'].toString().substring(0,7)})";
           String body =  message.data['token_name'].toString();


           mWallet.writeTransactionToHistory(
             direction: 'income',
             from:message.data['pubKey'] ,
             me:message.data['to'] ,
             net: message.data['net'],
             nftName:message.data['token_name'],
             nftId: message.data['token_id'],
             nftContract: message.data['contract_id'],
             txHash: message.data['tx'],
           );


           await flutterLocalNotificationsPlugin.show(
             0,
             title,
             body,
             platformChannelSpecifics,
             payload: '',
           );
           break;

       }





       if (message.notification != null) {
         print('Message also contained a notification: ${message.notification?.title.toString()}');
       }
     });





  }

  static Future<String> getUsernameByPubKey(String address) async  {

    DbHelper dbh  = DbHelper();
    Database db = await dbh.openDB();

    final data = await  db.query('contacts', where: 'wallet_address = ?', whereArgs: [address]);

    if(data.isNotEmpty){

      return data.first['user_name'].toString();
    }
    return "User";


  }


  static Future<String> getBearerToken() async{


    final String response = await rootBundle.loadString('assets/oAuth/walletapp-5d95f.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(response);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    //AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);


    var client = http.Client();
    AccessCredentials credentials = await obtainAccessCredentialsViaServiceAccount(accountCredentials, scopes, client);

    client.close();

    return credentials.accessToken.data;

  }




}