import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_application/NFTHelper.dart';
import 'package:wallet_application/NFTScreen.dart';
import 'package:wallet_application/add_network_page.dart';
import 'package:wallet_application/change_network_dialog.dart';
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


class UserActivity extends StatelessWidget {
  const UserActivity( {Key? key, required this.user, this.data}) : super(key: key);
  final User user;
  final Map<String, dynamic>? data;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return UserActivityPage( user: user, data: data);
  }
}



class UserActivityPage extends StatefulWidget {
  const UserActivityPage( {Key? key, required this.user, this.data}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  final User user;
  final Map<String, dynamic>? data;
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();

}

class _UserActivityPageState extends State<UserActivityPage> {
  late User user;
  bool _userNameVisibility = true;

  late Map<String,dynamic> data;
  dynamic userInfo = "";
  String userFcmToken = "";
  String userInst = "";

  Image? image;

  // var colorText = Colors.black;

  TextEditingController userNameController = TextEditingController();

  Icon _editIcom = Icon(Icons.mode_edit);


  var isPublic = false;
  var receiveEnabled = false;
  var instaEnabled = false;

  var sendEnabled = false;

  List<Asset> nfts = [];

  double amount = 0;
  String initialAmount = '0.0';



  @override
  void initState() {
    super.initState();
    user = widget.user;

    if(mWallet.currentNet != mNetworks.unknownNet){
      sendEnabled = true;
    }

    if(widget.data!=null) {
      data = widget.data!;

      initialAmount = data['amount'];

      if(data['net'] != mWallet.currentNet.rpcURL) {
          Future.sync(() async{
          SchedulerBinding.instance?.addPostFrameCallback((_){
            AlertDialog ad =  AlertDialog(
              title: Text('Request network is different'),
              content: Text("Want to change a network?"),
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
                    child: const Text('Change')
                )
              ],
            );
            showDialog(context: context, builder: (context){
              return ad;
            }).then((value) async{
              if(value) {
                await checkRequestNet(data['net']);
              }
            });
          });

        });
      }


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
        userInst = userInfo['instagram'];
        setState(() {

          if(mWallet.currentNet == mNetworks.unknownNet){
            sendEnabled = false;
            receiveEnabled = false;
          }else {
            receiveEnabled = true;
          }
          if (userInst != '') {
            instaEnabled = true;
          }
        });
      }


    });

    _getNfts();

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

  _getNfts() async{

    var list =  await NFT.getTestNFT(user.pubKey);
    if(list!=null) {
      setState(() {
        // nfts
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0])
        //   ..add(list[0]);
        nfts = list;
      });
    }

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
          btn_add_contact = "Remove from Contacts";
        }
      });
    }
  }

  _updateUserDB() async {
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();

    int i = await db.rawUpdate(
        "UPDATE contacts SET user_name = ? ,avatar = ?  WHERE wallet_address = '${user.pubKey}'",
        [user.name, user.avatar]);


    db.close();
  }



  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2.9;
    final double itemWidth = size.width / 2;


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){

            //Provider.of<ContactsProvider>(context, listen: false).updateContacts();
            Navigator.pop(context);
          },
        ),
        backgroundColor: mColors.light,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text(''),
        actions: instaEnabled? <Widget>[
          instagramButton(),
        ] : <Widget>[
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return RefreshIndicator(
            onRefresh: () async {
              await mWallet.updateBalance();
              setState(() {
                if(mWallet.currentNet != mNetworks.unknownNet){
                  sendEnabled = true;
                }
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                color: mColors.light,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      //user info
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: mColors.light, borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20))),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                    child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: user.avatar == "null" ? Colors.primaries[user.name.length] : Colors.white,

                                        child: user.avatar == "null" ? Text(user.name[0], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)) :
                                        ClipOval(
                                          child: Image.file(File(user.avatar),
                                            fit: BoxFit.cover,
                                            width: 150,
                                            height: 150,
                                          ),
                                        )
                                      // child:

                                    ),
                                  ),
                                  Visibility(
                                    visible: true,
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: TextButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: StadiumBorder(),
                                            primary: mColors.pubKeyColor,
                                          ),
                                          key: const Key('chenge_icon'),
                                          // style: ElevatedButton.styleFrom(
                                          //   splashFactory: NoSplash.splashFactory,
                                          // ),
                                          onPressed: () async {
                                            final imageNew = (await ImagePicker()
                                                .pickImage(source: ImageSource.gallery)
                                                .whenComplete(() =>
                                            {
                                            }));
                                            if (imageNew != null) {
                                              setState(() {
                                                user.avatar = imageNew.path;
                                                _updateUserDB();
                                              });
                                            }
                                          },
                                          child: Text("Set New Photo", style: TextStyle(
                                              fontSize: 12, color: Colors.black)
                                            ,)
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                margin: EdgeInsets.all(8),

                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Visibility(
                                        visible: !_userNameVisibility,
                                        child: Container(
                                          width: 150,
                                          margin: const EdgeInsets.fromLTRB(30, 10, 0, 0),
                                          child: TextField(
                                            maxLength: 15,
                                            controller: userNameController,
                                            style: TextStyle(fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        margin: EdgeInsets.fromLTRB(25, 0, 0, 0),
                                        child: Visibility(
                                            visible: _userNameVisibility,
                                            child: Text(user.name, style: TextStyle(fontSize: 22,
                                                fontWeight: FontWeight.bold),)),
                                      ),


                                      IconButton(
                                          iconSize: 18,
                                          //padding: const EdgeInsets.all(3),
                                          onPressed: () {
                                            setState(() {
                                              if (_userNameVisibility) {
                                                userNameController.text = user.name;
                                                _editIcom = Icon(Icons.check);
                                              } else {
                                                user.name = userNameController.text;

                                                _editIcom = Icon(Icons.mode_edit);
                                                _updateUserDB();
                                              }

                                              _userNameVisibility = !_userNameVisibility;
                                            });
                                          },
                                          icon: _editIcom),
                                    ]),
                              ),

                              Container(
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:  <Widget>[
                                    Material(
                                      color: mColors.pubKeyColor,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: (){
                                          //Simple to use, no global configuration
                                          showToast("public key copied",context:context);
                                          Clipboard.setData(ClipboardData(text: user.pubKey));
                                        },
                                        child: Container(
                                          width: 200,
                                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: Colors.transparent),
                                          child:
                                          Text(
                                              user.pubKey,
                                              overflow: TextOverflow.ellipsis
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.transparent),
                              child: TextButton(
                                  onPressed: (){
                                    if(btn_add_contact == "Add to Contacts"){
                                      _addUserToContacts();
                                    }else{
                                      _removeUserFromContacts();
                                    }
                                  },
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(16)),
                                      backgroundColor: MaterialStateProperty.all<Color>(mColors.walletColor),
                                      overlayColor: MaterialStateProperty.all<Color>(mColors.shadowGray),
                                      elevation: MaterialStateProperty.all<double>(2.0),
                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: Colors.transparent),

                                          )
                                      )
                                  ),
                                  child: Text(btn_add_contact, style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: mColors.white))),

                            ),
                          ),

                        ],
                      ),


                      Container(
                        padding: EdgeInsets.fromLTRB(12, 24, 12, 12),
                        margin: EdgeInsets.fromLTRB(8, 10, 8, 10),
                        decoration: BoxDecoration(color: mColors.light,borderRadius: BorderRadius.circular(20),),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                              child: Text("Transaction via ${mWallet.provider?.connector.session.peerMeta?.name.toString()}",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                            ),
                            Divider(
                              height: 10,
                            ),
                            Container(
                              margin: EdgeInsets.fromLTRB(22, 15, 0, 10),
                              child: Text("Your wallet",style: TextStyle(backgroundColor: Colors.transparent, fontSize: 15)
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Colors.transparent,
                            ),
                            Container(
                              margin: EdgeInsets.fromLTRB(8,4,8,8),
                              child: Column(
                                children: [
                                  Row(
                                    children:  <Widget>[
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(20, 5, 27, 5),
                                        child: Text("Network:",style: TextStyle(fontWeight: FontWeight.bold),),
                                      ),
                                      Flexible(
                                        child: Container(
                                          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                          child: Material(
                                            color:  mColors.pubKeyColor,
                                            borderRadius: BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () async {
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
                                                AlertDialog ad = await buildNetworkDialog(context);
                                                showDialog(context: context, builder: (context){
                                                  return ad;
                                                }).then((net) async {
                                                   final tx = await mWallet.changeNetwork(net);
                                                   print("Switch Chain TX: "+tx.toString());
                                                   if(tx is int){
                                                     showToast('Chain switched to $tx', context: context, duration: Duration(seconds: 5));

                                                   }
                                                   if (tx.toString() !=
                                                       'JSON-RPC error -32000: User rejected the request.') {
                                                     if (tx.toString().startsWith('JSON-RPC error -32000: Unrecognized chain ID')) {
                                                         requestAddChain(net);
                                                     } else {


                                                     }
                                                   }
                                                   else {
                                                     showToast('Request rejected',
                                                         context: context,
                                                         duration: Duration(
                                                             seconds: 5));
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
                                        margin: const EdgeInsets.fromLTRB(20, 8, 27, 15),
                                        child: Text("Balance:",style: TextStyle(fontWeight: FontWeight.bold),),
                                      ),
                                      Container(
                                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
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

                            Divider(
                              height: 10,
                            ),

                            Container(
                              margin: EdgeInsets.fromLTRB(22, 15, 0, 10),
                              child: Text("Send transaction",style: TextStyle(backgroundColor: Colors.transparent,fontSize: 15)
                              ),
                            ),

                            Divider(
                              height: 1,
                              color: Colors.transparent,
                            ),



                            Container(
                              margin: EdgeInsets.fromLTRB(8,8,8,8),
                              padding: EdgeInsets.fromLTRB(4,10,10,4),

                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:  <Widget>[
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(20, 25, 27, 5),
                                        child: Text("Amount:",style: TextStyle(fontWeight: FontWeight.bold),),
                                      ),
                                      Container(
                                        width: 150,
                                        margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                        child: Material(
                                          color:  Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          child: TextFormField(
                                            initialValue: initialAmount,
                                            autovalidateMode: AutovalidateMode.always,
                                            keyboardType:  TextInputType.number,
                                            textInputAction: TextInputAction.done,
                                            inputFormatters: <TextInputFormatter>[
                                              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                                            ],
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: mColors.pubKeyColor,
                                                border: OutlineInputBorder(
                                                  gapPadding: 0,
                                                  borderRadius: BorderRadius.circular(10)
                                                ),
                                            ),
                                            validator: (value){
                                              if(value!=null) {
                                                final newAmount = double.tryParse(value);
                                                if(newAmount!=null) {
                                                  amount = newAmount;
                                                }else{
                                                  amount = -1;
                                                }

                                              }

                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(10, 25, 0, 5),
                                        child: Text(mWallet.currentNet.coinName,style: TextStyle(fontWeight: FontWeight.bold),),
                                      )
                                    ],
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children:  <Widget>[
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(0, 20, 40, 0),
                                        padding: const EdgeInsets.all(5),
                                        child: ElevatedButton(
                                          onPressed: receiveEnabled ? (){
                                            if(amount>0) {
                                              requestTransaction();
                                            } else {
                                              showToast("Invalid amount", context: context);
                                            }

                                          }:(){

                                          },

                                          style: ElevatedButton.styleFrom(shape: new RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.circular(30.0),

                                            ),
                                            primary: receiveEnabled? null : Colors.blueGrey
                                          ),
                                          child: receiveEnabled? Text("Receive"): Text("Not allowed"),
                                        ),
                                      ),
                                      Container(
                                          margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                          padding: const EdgeInsets.all(5),
                                          //decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),color: Colors.tealAccent),
                                          child: ElevatedButton(
                                            onPressed: sendEnabled? () async{

                                              if(amount<mWallet.balance.getValueInUnit(EtherUnit.ether)&& amount>0) {
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
                                                final tx = await mWallet
                                                    .sendPayment(
                                                    amount, user.pubKey);

                                                if (tx.isNotEmpty) {
                                                  if(tx == "JSON-RPC error -32000: User rejected the transaction") {
                                                    showToast("Transaction rejected", context: context, duration: Duration(seconds: 5));
                                                  }else{

                                                    showToast("Transaction sent", context: context, duration: Duration(seconds: 5));


                                                    notifyReceiver(tx);

                                                  }
                                                  await mWallet.updateBalance();

                                                  setState(() {


                                                  });

                                                }
                                              }else{
                                                showToast("Invalid amount", context: context);
                                              }
                                            }:(){
                                              showToast("Please setup network first", context: context);
                                            },
                                            style: ElevatedButton.styleFrom(shape: new RoundedRectangleBorder(
                                                borderRadius: new BorderRadius.circular(30.0),
                                                ),
                                                primary: sendEnabled? null : Colors.blueGrey
                                            ),
                                            child: sendEnabled? Text("Send"): Text("Not allowed"),
                                          ),
                                      )
                                    ],
                                  ),

                                ],
                              ),
                            ),

                          ],
                        ),
                      ),


                      nfts.isNotEmpty ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  margin: EdgeInsets.fromLTRB(16, 24, 0, 0),
                                  child: Text("OpenSea Gallery",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mColors.Gay))
                              ),
                            ],
                          ),

                          Container(
                            padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            decoration: BoxDecoration(color: mColors.light,borderRadius: BorderRadius.circular(20),),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: (itemWidth / itemHeight),
                                        crossAxisSpacing: 0,
                                        mainAxisSpacing: 0),
                                    itemCount: nfts.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (BuildContext ctx, index) {
                                      return Material(
                                        type: MaterialType.transparency,
                                        child: Container(
                                          margin: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            //Here goes the same radius, u can put into a var or function
                                            borderRadius:
                                            BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: mColors.shadowGray,
                                                  spreadRadius:0.8,
                                                  blurRadius: 1.3,
                                                  offset: Offset(0.0, 1.0)
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              decoration: BoxDecoration(
                                              //  borderRadius: BorderRadius.circular(10),
                                                color: nfts[index].backgroundColor == null ? mColors.white: nfts[index].backgroundColor,
                                                // boxShadow: [ BoxShadow(
                                                //   color: Colors.grey,
                                                //   offset: Offset(3.0, 3.0), //(x,y)
                                                //   blurRadius: 3.0,
                                                //   )
                                                // ],
                                              ),
                                              child: Material(
                                                type: MaterialType.transparency,
                                                child: InkWell(
                                                  splashColor: mColors.Gay,
                                                  onTap: (){
                                                    Navigator.push(context, MaterialPageRoute(builder: (context){
                                                      return NFTScreen(nft: nfts[index]);
                                                    }));
                                                  },
                                                  child: Ink(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Center(
                                                            child: Image.network(
                                                              nfts[index].imageUrl,
                                                              height:itemWidth-20,
                                                              fit: BoxFit.contain,
                                                            )
                                                        ),
                                                        Container(
                                                          child: Text(nfts[index].name,
                                                            style: TextStyle(), textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis,),
                                                          margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
                                                          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ],
                            ),
                          ),
                        ],
                      ) : SizedBox(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  String btn_add_contact = "Add to Contacts";

  void _addUserToContacts() async{
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();

      int i = await db.rawInsert(
          "INSERT INTO contacts (user_name,avatar,wallet_address) VALUES ('${user.name}','null','${user.pubKey}')");

      db.close();

      setState(() {
        btn_add_contact = "Remove from Contacts";
      });

  }

  void _removeUserFromContacts() async{
      DbHelper dbh = DbHelper();

      Database db = await dbh.openDB();

      int i = await db.delete('contacts', where: "wallet_address = '${user.pubKey}'");

      db.close();

      if(i>0) {
        setState(() {
          btn_add_contact = "Add to Contacts";
        });
      }else{
        showToast("Failed to remove",context: context);
      }

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

  Future<bool> checkRequestNet(String rpcUrl) async {
    if(mWallet.currentNet.rpcURL== rpcUrl){
      return true;
    }

    List<Network> networks = [...mNetworks.networks];
    networks.addAll(await mWallet.getListNetworks());
    if(networks.any((element) => element.rpcURL == rpcUrl)){

      final net = networks.firstWhere((element) => element.rpcURL == rpcUrl);
      final tx = await mWallet.changeNetwork(net);

      print("Switch Chain TX: "+tx.toString());
      if(tx is int){
        showToast('Chain switched to $tx', context: context, duration: Duration(seconds: 5));

        return true;
      }

      if (tx.toString() !=
          'JSON-RPC error -32000: User rejected the request.') {
        if (tx.toString().startsWith('JSON-RPC error -32000: Unrecognized chain ID')) {
            requestAddChain(net);
        } else {

        }
      }
      else {
        showToast('Request rejected',
            context: context,
            duration: Duration(
                seconds: 5));
      }
      return true;
    }else{
      final net = Network(name: rpcUrl, rpcURL: rpcUrl, chainID: data['chain_id'], coinName: data['currency']);
      requestAddChainToApp(net);

      return true;
    }

    return false;

  }

  void requestAddChainToApp(Network net) {
    AlertDialog ad =  AlertDialog(
      title: Text('Network not found in ToNear'),
      content: Text("Want to add a network to your App?"),
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
        final res = await  saveNewNetwork(net);
        print("Network Add: " + res.toString());
        if(res == "Network Add Success"){
          showToast('Chain added', context: context, duration: Duration(seconds: 5));
          checkRequestNet(net.rpcURL);
        }
        else{
          showToast('Failed to add chain', context: context, duration: Duration(seconds: 5));
        }
      }
    });

  }

  instagramButton() {
    final onPressed = () async {
      final nativeUrl = 'instagram://user?username=$userInst';
      final webUrl = 'https://www.instagram.com/$userInst/';


      if (await canLaunch(nativeUrl)) {
        await launch(nativeUrl);
      } else if (await canLaunch(webUrl)) {
        await launch(webUrl);
      } else {
        print("can't open Instagram");
      }
    };
    return IconButton(onPressed: onPressed,
        icon: Image.asset(
          'assets/images/instagram.png'
        )
    );

  }


}



