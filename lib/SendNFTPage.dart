import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/NFTHelper.dart';
import 'package:wallet_application/change_network_dialog.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/firebaseHelper.dart';
import 'package:wallet_application/server.dart';
import 'package:wallet_application/wallet.dart';
import 'package:http/http.dart' as http;
import 'Contacts/provider/contacts_provider.dart';
import 'Contacts/widget/contact_listtile_widget.dart';
import 'User.dart';
import 'dbHelper.dart';



class SendNFTActivity extends StatelessWidget {

  const SendNFTActivity( {
      Key? key,
      this.nft,
      this.data,
      this.isSend = true,
      this.user

    }
  ) : super(key: key);

  final Asset? nft;
  final Map<String, dynamic>? data;
  final bool isSend;
  final User? user;
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return SendNFTActivityPage( nft: nft, data: data, isSend: isSend, user: user);
  }

}



class SendNFTActivityPage extends StatefulWidget {
  const SendNFTActivityPage( {Key? key, required this.nft, this.data, required this.isSend, this.user}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  final Asset? nft;
  final Map<String, dynamic>? data;
  final bool isSend;
  final User? user;
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<SendNFTActivityPage> createState() => _SendNFTActivityPageState();

}

class _SendNFTActivityPageState extends State<SendNFTActivityPage> {
  Asset? nft;

  late Map<String,dynamic> data;

  Image? image;

  User? user;

  // var colorText = Colors.black;

  TextEditingController userNameController = TextEditingController();


  var isPublic = false;

  var sendEnabled = false;

  var nftAvailable = false;


  @override
  void initState() {
    super.initState();

    if(widget.data!=null) {
      data = widget.data!;



    }


    if(widget.nft!=null){
      nft = widget.nft!;
      nftAvailable = true;
    }
    else {

      _getNft();

    }





    user = widget.user;

    if(user!=null) {

      text = user!.pubKey;
      _textFieldController.text = user!.pubKey;
    }


    if(mWallet.provider==null) {
      mWallet.walletReconnect(context).then((value) => setState((){

      }));
    }



    Future.sync(() async {
      await _initDB();

    });


    mWallet.updateCallback = (){
      setState(() {
        if(mWallet.currentNet == mNetworks.unknownNet){
          sendEnabled = false;
        }else {
          sendEnabled = _checkKey(text);

        }
      });
    };
  }

  String nftNetName(Asset nft){

    return nft.originalLink.substring(8).split('/')[2];

  }


  bool _checkKey(String key){


    return (key.startsWith("0x")&&key.length == 42&&key.substring(2).contains(new RegExp('^[a-fA-F0-9]*')))||(key.length == 40 && key.contains(new RegExp('^[a-fA-F0-9]*')) && nftAvailable );


  }

  _initDB() async {
    DbHelper dbh = DbHelper();

    Database db = await dbh.openDB();


  }


  //String sendAddress = '';
  TextEditingController _textFieldController = TextEditingController();
  String text = '';


  bool containsSearchText(User user) {
    final name =  user.name;
    final pub = user.pubKey;
    final textLower = text.toLowerCase();
    final contactLower = name.toLowerCase();
    final pubLower = pub.toLowerCase();

    return (contactLower.contains(textLower)||pubLower.contains(textLower));
  }


  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) => ContactsProvider(),
      builder: (context, child){
        final provider = Provider.of<ContactsProvider>(context);
        final allContacts = provider.contacts;
        final contacts = allContacts.where(containsSearchText).toList();
        return Scaffold(
          appBar: AppBar(

            centerTitle: true,
            title: Container(
              margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Text("Current network", style: TextStyle(fontSize: 14, color: mColors.dark, letterSpacing:0.5 ),),
                      Text(
                        mWallet.currentNet.name,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(fontSize: 10, color: mColors.dark, letterSpacing:0.5),
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: mColors.transparent,
                        overlayColor: MaterialStateProperty.all<Color>(mColors.transparent),
                        highlightColor: mColors.antiShadowGray,
                        onTap: _changeNetworkTap,
                      ),
                    ),
                  ),

                ],
              ),
            ),


            backgroundColor: mColors.gray040,
            foregroundColor: Colors.black,
            elevation: 0,

          ),
          body: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints viewportConstraints) {

                return Column(
                  children: [
                    Column(
                      children: [
                        Container(
                          color: mColors.gray040,
                          child: Column(
                            children: [
                              // Container(
                              //     margin: EdgeInsets.all(20),
                              //     child: Text("Send to address", style: TextStyle(fontSize: 18),)),
                              Container(
                                margin: EdgeInsets.fromLTRB(22, 8, 16, 22),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      text = value;
                                      sendEnabled = _checkKey(text);
                                    });
                                  },
                                  controller: _textFieldController,
                                  decoration: InputDecoration(
                                    suffixIcon: Visibility(
                                      visible: text.isNotEmpty,
                                      child: IconButton(onPressed: (){
                                        setState(() {
                                          _textFieldController.text = '';
                                          text = '';
                                          sendEnabled = false;
                                        });
                                      }, icon: Icon(Icons.clear)),
                                    ),
                                    hintText: "Search, public address (0x)",
                                    filled: true,
                                    fillColor: mColors.pubKeyColor,
                                    border: OutlineInputBorder(
                                        gapPadding: 0,
                                        borderRadius: BorderRadius.circular(10)
                                    ),

                                  ),
                                ),
                              ),


                              Container(
                                margin: EdgeInsets.fromLTRB(22, 0, 0, 20),
                                child:sendEnabled? Row(
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(text: 'Attention! ', style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold, color: mColors.aggressionRed)),
                                          TextSpan(text: 'This NFT is based on ', style: TextStyle()),
                                          TextSpan(text: nftNetName(nft!), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mColors.blue300)),
                                          TextSpan(text: ' network.\nPlease make sure your current network is ', style: TextStyle()),
                                          TextSpan(text: nftNetName(nft!), style: TextStyle(fontSize: 14)),
                                          TextSpan(text: '.', style: TextStyle()),
                                        ],
                                      ),

                                    ),
                                  ],
                                ): SizedBox(),
                              ),


                              Divider(height: 1,thickness: 1,),
                            ],
                          ),
                        ),

                        Container(
                          color: mColors.gray040,
                          padding: EdgeInsets.all(14),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(

                                margin: EdgeInsets.fromLTRB(8, 0, 0, 0) ,
                                child: Text("Select contact", style: TextStyle(),),
                              ),
                            ],
                          ),
                        ),

                      ],

                    ),
                    Divider(height: 1,thickness: 1,),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: contacts.length,
                        itemBuilder: (context, index){

                          User user = contacts[index];

                          return ContactListTileWidget(
                            user: user,
                            isSelected: false,
                            onSelectedUser: (user){

                            },
                            onTapUser: tapUser,
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider();
                        },
                        // children: contacts.map((user) {
                        //   final isSelected = selectedContacts.contains(user);
                        //
                        //   return ContactListTileWidget(
                        //     user: user,
                        //     isNative: isNative,
                        //     isSelected: isSelected,
                        //     onSelectedUser: selectUser,
                        //   );
                        // }).toList(),
                      ),
                    ),
                    buildSelectButton(context),


                  ],

                );

              }
          ),
        );
      },
    );
  }


  void tapUser(User user) async{

    setState(() {
      _textFieldController.text = user.pubKey;
      text = user.pubKey;
      sendEnabled = _checkKey(text);
    });

  }


  Widget buildSelectButton(BuildContext context) {

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: mColors.light,
      child: ElevatedButton(

        style: ElevatedButton.styleFrom(
          shape: StadiumBorder(),
          minimumSize: Size.fromHeight(40),
          primary: mColors.walletColor,
        ),
        child: Text(
          "Send",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        onPressed: sendEnabled? () async {

         // notifyReceiver('0x0000000000000000000dead');
          if(nft!=null) {
            final tx = await mWallet.sendNFT(nft!, text);

            if (tx.isNotEmpty) {
              if (tx ==
                  "JSON-RPC error -32000: User rejected the transaction") {
                showToast("Transaction rejected", context: context,
                    duration: Duration(seconds: 5));
              } else {
                showToast("Transaction sent", context: context,
                    duration: Duration(seconds: 5));
                notifyReceiver(tx);
              }
              await mWallet.updateBalance();

              setState(() {

              });
            }
          }

        }:null,
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

  Future<String> getUserToken() async {
    final userInfo = await Server.getUser(text);
    if(userInfo!="") {
      return userInfo['fireToken'];
    }
    return '';

  }

  void notifyReceiver(String tx) async {
    var name = await getMyName();

    final userFcmToken = await getUserToken();

    if(userFcmToken.isNotEmpty) {
      final token = await FirebaseHelper.getBearerToken();
      print(token);

      final body =jsonEncode(<String, dynamic>{
        "message": {
          "token": userFcmToken,
          "data": {
            "message": "You received NFT",
            "token_id": nft?.tokenId,
            "token_name": nft?.name,
            "name":name,
            "contract_id": nft?.contractAddress,
            "collection_name": nft?.collectionName,
            "pubKey": mWallet.account.toLowerCase(),
            "to": text,
            "tx": tx,
            "net":mWallet.currentNet.rpcURL
          },
          "notification": {
            "title": "You received NFT from $name (${mWallet.account
                .toString().substring(0, 7)})",
            "body": "${nft?.name}"
          },
        },


      });
      print(body);

      var responce = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/walletapp-5d95f/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('${responce.statusCode} ${responce.reasonPhrase}');

    }



    mWallet.writeTransactionToHistory(
        direction: "outcome",
        net: mWallet.currentNet.rpcURL,
        from: text,
        me: mWallet.account.toLowerCase(),
        nftName: nft!.name,
        nftId: nft!.tokenId,
        nftContract: nft!.contractAddress,
        txHash: tx,
    );
    
    Navigator.of(context).pop();
  }




  _changeNetworkTap () async {
    mWallet.updateCallback = (){
      setState(() {
        if(mWallet.currentNet == mNetworks.unknownNet){
          sendEnabled = false;
        }else {
          sendEnabled = _checkKey(text);
        }
      });
    };
    AlertDialog ad = await buildNetworkDialog(context);
    showDialog(context: context, builder: (context){
      return ad;
    }).then((net) async {
      if(net!=null) {
        final tx = await mWallet.changeNetwork(net);
        print("Switch Chain TX: " + tx.toString());
        if (tx is int) {
          showToast('Chain switched to $tx', context: context,
              duration: Duration(seconds: 5));
        }
        if (tx.toString() !=
            'JSON-RPC error -32000: User rejected the request.') {
          if (tx.toString().startsWith(
              'JSON-RPC error -32000: Unrecognized chain ID')) {
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
      }

    });
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

  Future<Asset?> getAssetFromData(Map<String, dynamic> data) async {

    return await NFT.getTestSingleNFT(data['token_id'], data['contract_id'], owner: data['pubKey']);

  }

  void _getNft() async {
    final asset = await getAssetFromData(data);

    if(asset!=null){
      nft = asset;
      nftAvailable = true;
      sendEnabled = _checkKey(text);
    }

    setState(() {

    });
  }

}