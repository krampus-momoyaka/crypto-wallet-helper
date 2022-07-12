
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info/device_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/Contacts/widget/avatar_widget.dart';
import 'package:wallet_application/NFTHelper.dart';
import 'package:wallet_application/UserActivity.dart';
import 'package:wallet_application/change_network_dialog.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:wallet_application/server.dart';
import 'package:wallet_application/wallet.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet_application/firebaseHelper.dart';

import 'Contacts/page/contacts_page.dart';
import 'Contacts/provider/contacts_provider.dart';
import 'History/page/history_page.dart';
import 'History/provider/history_provider.dart';
import 'Logo.dart';
import 'User.dart';
import 'add_network_page.dart';
import 'package:firebase_core/firebase_core.dart';



void _onMessageOpenedApp(RemoteMessage message) async {

  await Firebase.initializeApp();

  final data = message.data;
  FirebaseHelper.notificationData = data['pubKey'].toString();
  print('opened App');
  if(data['message']=='Transaction request') {
    navigatorKey.currentState?.pushNamed('/UserActivity',arguments: {'user': User(data['name'],data['pubKey']),'message': message.data});
  }



}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();



  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //
  // AndroidNotificationDetails _androidNotificationDetails =
  // AndroidNotificationDetails(
  //   'channel ID',
  //   'channel name',
  //   channelDescription :'channel description',
  //   playSound: true,
  //   priority: Priority.max,
  //   importance: Importance.max,
  // );
  //
  // IOSNotificationDetails _iosNotificationDetails = IOSNotificationDetails(
  //     presentAlert: null,
  //     presentBadge: null,
  //     presentSound: null,
  //     badgeNumber: null,
  //     attachments: null,
  //     subtitle: null,
  //     threadIdentifier: null
  // );
  //
  //
  //
  // NotificationDetails platformChannelSpecifics =
  // NotificationDetails(
  //     android: _androidNotificationDetails,
  //     iOS: _iosNotificationDetails);
  //
  // const AndroidInitializationSettings initializationSettingsAndroid =
  // AndroidInitializationSettings("launch_background");
  //
  // /// Note: permissions aren't requested here just to demonstrate that can be
  // /// done later
  // final IOSInitializationSettings initializationSettingsIOS =
  // IOSInitializationSettings(
  //   requestAlertPermission: false,
  //   requestBadgePermission: false,
  //   requestSoundPermission: false,
  //   onDidReceiveLocalNotification: null,
  // );
  //
  // final InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  //   iOS: initializationSettingsIOS,
  // );
  //
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings,
  //     onSelectNotification: (String? payload) async {
  //       if (payload != null) {
  //         print('notification payload: $payload');
  //       }
  //
  //       //selectedNotificationPayload = payload;
  //       //selectNotificationSubject.add(payload);
  //     });
  //
  // FirebaseHelper.flutterLocalNotificationsPlugin.show(0, "hello", "",  platformChannelSpecifics);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel_id', 'channel_name', channelDescription: 'channel_description',
        importance: Importance.max, priority: Priority.high);

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android:androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    //flutterLocalNotificationsPlugin.show(0, "hello", "",  platformChannelSpecifics);

  print("Handling a background message: ${message.messageId}");

  if(message.data['message']=='You received Transaction'){
    print('terminate message data:' + jsonEncode(message.data));


    isDefaultLaunch = true;
    mWallet.writeTransactionToHistory(
      direction: 'income',
      from:message.data['pubKey'] ,
      me:message.data['to'] ,
      net: message.data['net'],
      coinName:message.data['currency'],
      amount: message.data['amount'],
      txHash: message.data['tx'],
    );
  }



}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future main() async {




  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}



class Profile extends StatelessWidget {

  const Profile( {Key? key,}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
        ChangeNotifierProvider (
          create: (context) => ContactsProvider(),
        ),
        ChangeNotifierProvider (
          create: (context) => HistoryProvider(),
        ),

    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(
      //   primarySwatch: mColors.appBarColor,
      // ),
      home: ProfilePage(),
    ),
  );
}

enum DeviceType { advertiser, browser }


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final DeviceType deviceType = DeviceType.browser;

  @override
  State<ProfilePage> createState() => _ProfilePageState();

}

class _ProfilePageState extends State<ProfilePage> {

  String userName = "User";
  bool _userNameVisibility = true;
  String imagePath = 'null';

  List<Device> devices = [];
  List<User> users = [];
  late NearbyService nearbyService;

  bool blueInit = false;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  String InstagramAction = "Add Instagram";

 // var colorText = Colors.black;

  TextEditingController userNameController = TextEditingController();

  Icon _editIcom = Icon(Icons.mode_edit);

  Image image = Image.asset("assets/images/no-avatar.png",
  fit: BoxFit.scaleDown,
  width: 150,
  height: 150,
  );

  var isPublic = false;


  @override
  void initState() {




    super.initState();





    mWallet.updateCallback = (){
      setState(() {

      });
    };

    if(mWallet.provider==null) {
      mWallet.walletReconnect(context).then((value) => setState((){

      }));
    }

    Future.sync(() async{

      await _initDB();
      initBluetooth();
    });

  }

  _initDB() async{
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();


    final user = await db.query('user_info');


    if(user.isNotEmpty) {
      Map<String, dynamic> mapRead = user.first;
      setState(() {
        if (mapRead['user_name'] != null) {
          userName = mapRead['user_name'];
          imagePath = mapRead['avatar'];
          if(mapRead['instagram']!='' && mapRead['instagram']!=null) {
            setState(() {
              InstagramAction = "Remove Instagram";
            });
          }
          userNameController.text = userName;
        }
      });
    }else{
      int i = await db.rawInsert("INSERT INTO user_info (user_name,avatar,wallet_address) VALUES ('User','null','${mWallet.account}')");
    }

    if(imagePath!='null'){
      image = Image.file(File(imagePath),
        fit: BoxFit.scaleDown,
        width: 150,
        height: 150,
      );
    }else{
      image = Image.asset("assets/images/no-avatar.png",
        fit: BoxFit.scaleDown,
        width: 150,
        height: 150,
      );
    }

  }

  _updateUserDB() async {
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();

    int i = await db.rawUpdate("UPDATE user_info SET user_name = ? ,avatar = ? ,wallet_address = ?",[userName,imagePath,mWallet.account]);

    users.clear();


    if(!blueInit) {
      await nearbyService.init(
          serviceType: 'walletserv',
          deviceName: _formPublicName(),
          strategy: Strategy.Wi_Fi_P2P,
          callback: (isRunning) async {
            if (isRunning) {
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(Duration(microseconds: 200));
              if (isPublic) {
                await _changePublicMode(true);
              }
              await nearbyService.startBrowsingForPeers();

              blueInit = true;
            } else {
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(Duration(microseconds: 200));
              if (isPublic) {
                await _changePublicMode(true);
              }
              await nearbyService.startBrowsingForPeers();
            }
          }
      );
    }else{
      await nearbyService.stopBrowsingForPeers();
      await Future.delayed(Duration(microseconds: 200));
      if (isPublic) {
        await _changePublicMode(true);
      }
      await nearbyService.startBrowsingForPeers();
    }



    
    db.close();

  }

  _logout() async {
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();

    await db.rawDelete("DELETE FROM user_info");

    db.close();

    mWallet.killSession(context);
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('Do you want to exit an App'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
          TextButton(
            onPressed: (){
              subscription.cancel();
              receivedDataSubscription.cancel();
              nearbyService.stopBrowsingForPeers();
              nearbyService.stopAdvertisingPeer();
              Navigator.of(context).pop(true);
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    )) ?? false;
  }


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: mColors.light,
          foregroundColor: Colors.black,
          elevation: 1,
          title: const Text('Profile'),
          actions: <Widget>[
            contactsButton(),
            historyButton(),
            PopupMenuButton<String>(
              onSelected: (s){
                switch(s){

                  case "Logout":{
                    _logout();

                    break;
                  }
                  case "Add Network":{

                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      const AddNetworkPage()
                    ));
                    break;
                  }
                  case "Add Instagram" :{
                    _addInst();
                    break;
                  }
                  case "Remove Instagram" :{
                    _addInst();
                    break;
                  }

                }

              },
              itemBuilder: (BuildContext context) {
                return { 'Add Network',InstagramAction,'Logout'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body:
        LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
              return RefreshIndicator(
                onRefresh: () async {
                  mWallet.updateCallback = (){
                  setState(() {

                    });
                  };
                  await mWallet.updateBalance();

                  setState(() {

                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child:   Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        //user info
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: mColors.light,borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20))),
                          child: Material(
                            color: Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.white,
                                        child: ClipOval(
                                          child: image,
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: true,
                                      child: Container(
                                        padding : EdgeInsets.fromLTRB(4, 0, 0, 0),
                                        child: TextButton(
                                            key: const Key('chenge_icon'),
                                            // style: ElevatedButton.styleFrom(
                                            //   splashFactory: NoSplash.splashFactory,
                                            // ),
                                            onPressed: () async {

                                              final imageNew = (await ImagePicker().pickImage(source: ImageSource.gallery).whenComplete(() => {
                                              }));
                                              if(imageNew!=null) {
                                                setState(() {
                                                  imagePath = imageNew.path;
                                                  image = Image.file(
                                                    File(imagePath),
                                                    fit: BoxFit.scaleDown,
                                                    width: 150,
                                                    height: 150,
                                                  );
                                                  _updateUserDB();
                                                });
                                              }
                                              var i = 0;


                                            },
                                            child: Text("Set New Photo", style: TextStyle(fontSize: 17,color: Colors.black)
                                              ,)
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Visibility(
                                  visible: !_userNameVisibility,
                                  child: Container(
                                    width: 150,
                                    margin: const EdgeInsets.fromLTRB(0, 35, 0, 0),
                                    child: TextField(
                                      maxLength: 15,
                                      controller: userNameController,
                                      style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.fromLTRB(0, 45, 0, 0),
                                  child: Visibility(
                                      visible: _userNameVisibility,
                                      child: Text(userName, style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)),
                                ),
                                Container(
                                  margin: const EdgeInsets.fromLTRB(0, 30, 15, 0),
                                  child:
                                  IconButton(
                                    //padding: const EdgeInsets.all(3),
                                      onPressed: (){
                                        setState(() {
                                          if(_userNameVisibility){
                                            userNameController.text = userName;
                                            _editIcom = Icon(Icons.check);
                                          }else{
                                            userName = userNameController.text;

                                            _editIcom = Icon(Icons.mode_edit);
                                            _updateUserDB();
                                          }

                                          _userNameVisibility = !_userNameVisibility;


                                        });

                                      },
                                      icon: _editIcom),
                                )
                              ],
                            ),
                          ),
                        ),
                        //wallet
                        Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                          decoration: BoxDecoration(color: mColors.light,borderRadius: BorderRadius.circular(20),),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                                child: Text("Connected via ${mWallet.provider?.connector.session.peerMeta?.name.toString()}",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                              ),
                              Row(
                                children:  <Widget>[
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(20, 0, 27, 15),
                                    child: Text("Network:",style: TextStyle(fontWeight: FontWeight.bold),),
                                  ),
                                  Flexible(
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
                                      child: Material(
                                        color:  mColors.pubKeyColor,
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () async {
                                            mWallet.updateCallback = (){
                                              setState(() {

                                              });
                                            };
                                            AlertDialog ad = await buildNetworkDialog(context);
                                            showDialog(context: context, builder: (context){
                                              return ad;
                                            }).then((net) async {
                                              final tx = await mWallet.changeNetwork(net);
                                              print("Switch Chain TX: "+tx.toString());
                                              if(tx is int){
                                                showToast('Chain switched to $tx', context: context, duration: Duration(seconds: 5));

                                              }else {
                                                if (tx.toString() !=
                                                    'JSON-RPC error -32000: User rejected the request.') {
                                                  if (tx.toString().startsWith('JSON-RPC error -32000: Unrecognized chain ID')) {
                                                    setState(() {
                                                      requestAddChain(net);
                                                    });
                                                  } else {

                                                  }
                                                }
                                                else {
                                                  showToast('Request rejected',
                                                      context: context,
                                                      duration: Duration(
                                                          seconds: 5));
                                                }
                                              }

                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.transparent),
                                            child:
                                            Text(
                                                mWallet.currentNet.name,
                                                overflow: TextOverflow.ellipsis
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children:  <Widget>[
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(20, 0, 15, 0),
                                    child: Text("Public key:",style: TextStyle(fontWeight: FontWeight.bold),),
                                  ),
                                  Flexible(
                                    child: Material(
                                      color: mColors.pubKeyColor,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {





                                          //final s = tx.toString();


                                          //mWallet.sendRaw();

                                           //var nfts = await NFT.getTestNFT("0x65EB1b6A3Ab979B45e55Ffc560ccD8E072839fb3");



                                          //showToast(FirebaseHelper.notificationData,context: context);
                                          Clipboard.setData(ClipboardData(text: mWallet.account));
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: Colors.transparent),
                                          child:
                                          Text(
                                              mWallet.account,
                                              overflow: TextOverflow.ellipsis
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children:  <Widget>[
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(20, 15, 27, 15),
                                    child: Text("Balance:",style: TextStyle(fontWeight: FontWeight.bold),),
                                  ),
                                  Container(
                                      margin: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                                      padding: const EdgeInsets.all(10),
                                      //decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),color: Colors.tealAccent),
                                      child:
                                      Text(mWallet.balance.getValueInUnit(EtherUnit.ether).toString() + " ${mWallet.currentNet.coinName}")

                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        //ble
                        Container(
                          constraints: BoxConstraints(
                              minHeight: 150, minWidth: double.infinity, maxHeight: 300),
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.fromLTRB(10, 15, 10, 10),
                          decoration: BoxDecoration(color: mColors.light,borderRadius: BorderRadius.circular(20),),
                          child: Column(
                            //mainAxisSize: MainAxisSize.max,
                            children: [

                              Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(child: Text("People nearby", style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),)),
                                    const Text(
                                      "Public Mode",
                                    ),
                                    Switch(
                                      value: isPublic,
                                      onChanged: (value) {


                                        setState(() {
                                          isPublic = value;
                                          print(isPublic);
                                          _changePublicMode(value);
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                    // TextButton(child: Text("BLE"),onPressed: (){
                                    //     Navigator.push(context, MaterialPageRoute(builder:  (context) => Blue2()));
                                    //   },
                                    // ),
                                    Material(
                                      color: Colors.transparent,
                                      child: IconButton(
                                          onPressed:(){
                                            setState(() {
                                              _updateUserDB();
                                            });


                                          },
                                          icon: const Icon(IconData(
                                              0xe514,
                                              fontFamily: 'MaterialIcons'
                                          )
                                          )
                                      ),
                                    )

                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    //physics: const NeverScrollableScrollPhysics(),
                                    itemCount: getItemCount(),
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return Container(
                                        margin: EdgeInsets.all(5),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              if(user!=null) {

                                                //await connectUser(user);
                                                if(user.pubKey!="null") {
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              UserActivity(
                                                                  user: user))
                                                  );
                                                }
                                              }else{
                                                showToast("Failed",
                                                    context: context,
                                                    axis: Axis.horizontal,
                                                    alignment: Alignment.center,
                                                    position: StyledToastPosition.bottom);
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                                                          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                                          child:_deviceTextName(user),
                                                        ),
                                                        SizedBox(
                                                          height: 10.0,
                                                        ),
                                                        Divider(
                                                          height: 0.5,
                                                          color: Colors.grey,
                                                        )
                                                      ],
                                                    ),
                                                ),
                                                // GestureDetector(
                                                //   onTap: () => connectUser(user),
                                                //   child: Container(
                                                //     margin: EdgeInsets.symmetric(horizontal: 8.0),
                                                //     padding: EdgeInsets.all(8.0),
                                                //     height: 35,
                                                //     width: 100,
                                                //     color: getButtonColor(user.device!.state),
                                                //     child: Center(
                                                //       child: Text(
                                                //         getButtonStateName(user.device!.state),
                                                //         style: TextStyle(
                                                //             color: Colors.white,
                                                //             fontWeight: FontWeight.bold),
                                                //       ),
                                                //     ),
                                                //   ),
                                                // )
                                              ],

                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        ),



      ),
    );
  }



  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return "Connect";
      default:
        return "Disconnect";
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Colors.green;
      default:
        return Colors.red;
    }
  }


  int getItemCount() {
      return users.length;
  }

  initUserBle(List<User> userList) async{
    DbHelper dbh = DbHelper();
    Database db = await dbh.openDB();
    var c = await db.query('contacts');
    if(c.isNotEmpty) {
      c.forEach((element) {
        Map<String, dynamic> mapRead = element;
        if (mapRead['user_name'] != null) {
          if (userList
              .where((element) => element.pubKey == mapRead['wallet_address'])
              .isNotEmpty) {
            userList.where((element) =>
            element.pubKey == mapRead['wallet_address']).forEach((element) {
              element.name = mapRead['user_name'];
              element.avatar = mapRead['avatar'];
            });
          }

          // user.name = mapRead['user_name'];
          // user.avatar = mapRead['avatar'];
        }
      });
    }

    db.close();
    setState(() {
      users.clear();
      users.addAll(userList);

    });


  }

  initBluetooth() async {
    nearbyService = NearbyService();

    String devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    if(!blueInit) {
      await nearbyService.init(
          serviceType: 'walletserv',
          deviceName: _formPublicName(),
          strategy: Strategy.Wi_Fi_P2P,
          callback: (isRunning) async {
            if (isRunning) {
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(Duration(microseconds: 200));
              await _changePublicMode(isPublic);
              await nearbyService.startBrowsingForPeers();
              blueInit = true;
            } else {
              blueInit = false;
            }
          });
    }else{
      await nearbyService.stopBrowsingForPeers();
      await Future.delayed(Duration(microseconds: 200));
      await _changePublicMode(isPublic);
      await nearbyService.startBrowsingForPeers();
    }
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
          List<User> userList = [];
          devicesList.forEach((element) {
            if(checkCorrect(element.deviceName)) {


              User? user = _deviceToUser(element);
              if(user!=null) {
                if (user.pubKey.toString() != mWallet.account&& !userList.any((element) => element.pubKey == user.pubKey) ) {
                  userList.add(user);
                  // if(element.state == SessionState.connected) {
                  //   nearbyService.sendMessage(element.deviceId,
                  //       '{"request": true }');
                  // }
                }

                // if (users.every((element) => element.pubKey != user.pubKey)) {
                //   switch (element.state) {
                //     case SessionState.notConnected:
                //       if (user.pubKey.toString() != mWallet.account)
                //         nearbyService.invitePeer(deviceID: element.deviceId,
                //             deviceName: element.deviceName);
                //       break;
                //     case SessionState.connecting:
                //       break;
                //   }
                // }else{
                //   switch (element.state) {
                //     case SessionState.connected:
                //       if (user.pubKey.toString() != mWallet.account) {
                //         userList.add(user);

                //       }
                //
                //   }
                //}
              }

            }
            print(
                " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

            if (Platform.isAndroid) {
              if (element.state == SessionState.connected) {
                nearbyService.stopBrowsingForPeers();
              } else {
                //nearbyService.startBrowsingForPeers();
              }
            }

          });

          initUserBle(userList);

          // setState(() {
          //   devices.clear();
          //
          //   //for(int i = 0; i<10;i++) {
          //     devices.addAll(devicesList.where((element) =>
          //         checkCorrect(element.deviceName)));
          //   //}
          // });
        });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (data) {

          print("dataReceivedSubscription: ${jsonEncode(data)}");

          var messageInfo = jsonDecode( data['message']);

          if(messageInfo['request'] == true) {
            nearbyService.sendMessage(data['deviceId'],
                '{"pubKey":"${mWallet
                    .account}","FCM":"${FirebaseHelper.fcmToken
                    .toString()}"}');
            return;
          }


          String pubKey = messageInfo['pubKey'];
          String fcmToken = messageInfo['FCM'];
          // showToast(jsonEncode(data),
          //     context: context,
          //     axis: Axis.horizontal,
          //     alignment: Alignment.center,
          //     position: StyledToastPosition.bottom);
        });
  }


  String _formPublicName(){


    User user = User(userName, mWallet.account);

    String json = jsonEncode(user.toJson());
    return json;
  }

  _changePublicMode(bool enable) async{
    if(enable) {
      await nearbyService.stopAdvertisingPeer();
      await Future.delayed(Duration(microseconds: 200));
      await nearbyService.startAdvertisingPeer();
    }else{
      await nearbyService.stopAdvertisingPeer();
    }
  }

  bool checkCorrect(String deviceName) {
    bool correct = false;
    try{
      jsonDecode(deviceName);
      correct = true;
    }catch(e){
      correct = false;
    }
    return correct;
  }

  Widget contactsButton() {
    final onPressed = () async {
      Provider.of<ContactsProvider>(context, listen: false).updateContacts();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ContactsPage()),
      );
    };
    return IconButton(onPressed: onPressed, icon: Icon(Icons.star, color: mColors.gold));
  }
  Widget historyButton() {
    final onPressed = () async {
      Provider.of<HistoryProvider>(context, listen: false).updateHistory();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HistoryPage()),
      );
    };
    return IconButton(onPressed: onPressed, icon: Icon(Icons.history, color: Colors.black));
  }

  // Future<void> connectUser(User user) async {
  //   if(user.device!=null) {
  //     if(user.device!.state==SessionState.notConnected) {
  //       await nearbyService.invitePeer(
  //           deviceID: user.device!.deviceId,
  //           deviceName: user.device!.deviceName);
  //     }else{
  //
  //     }
  //   }
  // }

  void requestAddChain(net) async {
    AlertDialog ad =  AlertDialog(
      title: Text('Network not found in Metamask'),
      content: Text("Want to add a network to Metamask?"),
      actions: [
        TextButton(
            onPressed: (){
              Navigator.of(context, rootNavigator: true).pop(false);
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(true);
            },
            child: const Text('Add')
        )
      ],
    );
    showDialog(context: context, builder: (context){
      return ad;
    }).then((value) async{
      if(value){
        final tx = await mWallet.addNetwork(net);
        print("Switch Chain TX: "+tx.toString());
        if(tx is int){
          showToast('Chain switched to $tx', context: context, duration: Duration(seconds: 5));
        }
        if(tx.toString()!='JSON-RPC error -32000: User rejected the request.') {
        } else{
          showToast('Request rejected', context: context, duration: Duration(seconds: 5));
        }
      }else{

      }
    });
  }

  void _addInst() async {
    final dbh = DbHelper();
    final db = await dbh.openDB();
    if(db.isOpen) {
      final user = await db.query('user_info');

      db.close();
      if (user.isNotEmpty) {
        final inst = user.first['instagram'];
        if (inst != '' && inst != null) {
          _showRemoveInstDialog();
        }
        else {
          _showEnterInstDialog();
        }
      }
    }

  }

  void _showEnterInstDialog() {
    final tec = TextEditingController();
    var _validate = false;
    AlertDialog ad =  AlertDialog(
      title: Text('Enter Instagram profile'),
      content: TextField(
        controller: tec,
        decoration: InputDecoration(
          labelText: 'Enter Profile name',
          errorText: _validate ? "Value Can't Be Empty" : null,
        ),
      ),
      actions: [
        TextButton(
            onPressed: (){
              Navigator.of(context, rootNavigator: true).pop('');
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              if(tec.text!='') {
                Navigator.of(context, rootNavigator: true).pop(tec.text);
              }else{
                _validate = false;
              }
            },
            child: const Text('Add')
        )
      ],
    );
    showDialog(context: context, builder: (context){
      return ad;
    }).then((value) async{
      if(value!=''){
        Map<String, dynamic> row = {
          'instagram' : value,
        };

        final dbh = DbHelper();
        final db = await  dbh.openDB();
        final c = await db.update('user_info', row);
        if(c>0){
          final res = await Server.addUser(mWallet.account, FirebaseHelper.fcmToken!,await mWallet.getInsta());
          print(res);
          if(res == 'server: add_user success') {
            showToast('Instagram link Added', context: context);
            setState(() {
              InstagramAction = "Remove Instagram";
            });
          }
        }
        db.close();
      }
      else{

      }
    });


  }

  void _showRemoveInstDialog() {
    AlertDialog ad =  AlertDialog(
      title: Text('Instagram profile Added'),
      content: Text('Want to remove it?'),
      actions: [
        TextButton(
            onPressed: (){
              Navigator.of(context, rootNavigator: true).pop(false);
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(true);
            },
            child: const Text('Remove')
        )
      ],
    );
    showDialog(context: context, builder: (context){
      return ad;
    }).then((value) async{
      if(value){

        Map<String, dynamic> row = {
          'instagram' : '',
        };

        final dbh = DbHelper();
        final db = await  dbh.openDB();
        final c = await db.update('user_info', row);
        if(c>0) {
          final res = await Server.addUser(mWallet.account, FirebaseHelper.fcmToken!, '');

          if(res == 'server: add_user success'){
            showToast("Instagram link removed", context: context);
            setState(() {
              InstagramAction = "Add Instagram";
            });
          }
        }


      }

    });

  }

}

User? _deviceToUser(Device device){
  User user = User("Unknown user","null");
  try {
    user = User.fromJson(jsonDecode(device.deviceName));
    return user;
  }catch(e){
    print((e as FormatException).message);
  }

  return null;
}


 Row _deviceTextName(User user) {

    String text = user.name + " (" + user.pubKey.substring(2, 7) + ") ";

    Row name = Row(
      children: [
        AvatarWidget(avatar: user.avatar, name: user.name),
        Text(text)
      ],);
    return name;

}
