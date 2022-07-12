

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' as s;
import 'package:sqflite/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wallet_application/connector.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:wallet_application/firebaseHelper.dart';
import 'package:wallet_application/server.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:web3dart/web3dart.dart';


import 'main.dart';
import 'package:http/http.dart';
import 'network.dart';



 // class WalletConnectEthereumCredentials extends CustomTransactionSender {
 //    WalletConnectEthereumCredentials({required this.provider});
 //
 //    final EthereumWalletConnectProvider provider;
 //
 //    @override
 //    Future<EthereumAddress> extractAddress() {
 //      // TODO: implement extractAddress
 //      throw UnimplementedError();
 //    }
 //
 //    @override
 //    // Future<String> sendTransaction(Transaction transaction) async {
 //    //   final hash = await provider.sendTransaction(
 //    //     from: transaction.from!.hex,
 //    //     to: transaction.to?.hex,
 //    //     data: transaction.data,
 //    //     gas: transaction.maxGas,
 //    //     gasPrice: transaction.gasPrice?.getInWei,
 //    //     value: transaction.value?.getInWei,
 //    //     nonce: transaction.nonce,
 //    //   );
 //    //
 //    //   return hash;
 //    // }
 //
 //    @override
 //    Future<MsgSignature> signToSignature(Uint8List payload,
 //        {int? chainId, bool isEIP1559 = false}) {
 //      // TODO: implement signToSignature
 //      throw UnimplementedError();
 //    }
 // }

 class mWallet{

  static bool isSessionConnected = false;


  static late SessionStatus sessionStatus;
  static var account = '';


  //late InAppWebViewController _webViewController;

  static late var credentials;

  static EtherAmount balance = EtherAmount.zero();
  static EthereumWalletConnectProvider? provider;

  static late WalletConnect connector;

  static int? chainId;
  static Network currentNet = mNetworks.networks[0];


  static late Web3Client? client;

  static late Function updateCallback;



  static Future<List<Network>> getListNetworks() async {
      DbHelper dbh = DbHelper();

      s.Database db = await dbh.openDB();

      List<Network> nets = [];

      final c = await db.query('networks');

      if (c.isNotEmpty) {
        c.forEach((element) {Map<String, dynamic> mapRead = element;

        if (mapRead['rpc_url'] != null) {
          nets.add(Network(name:mapRead['net_name'],rpcURL: mapRead['rpc_url'], coinName: mapRead['coin_name'], chainID: mapRead['chain_id']));
        }
        });

      }
      db.close();

      return nets;
  }

  static sessionUpdateCallback (dynamic payload) async{
  print("\nupdate\n");
  chainId = connector.session.chainId;

  account = connector.session.accounts[0].toLowerCase();

  if(FirebaseHelper.fcmToken!=null) {
    final res = await Server.addUser(account, FirebaseHelper.fcmToken!,await getInsta());
    print(res);
  }

  connector.sessionStorage?.store(connector.session);

  List<Network> networks = [...mNetworks.networks];
  networks.addAll(await mWallet.getListNetworks());

  try {
    currentNet = networks.firstWhere((element) => element.chainID == chainId.toString());
  }catch(e){
    mNetworks.unknownNet.name = "Unknown (Chain ID ${chainId})";
    currentNet = mNetworks.unknownNet;
  }

  client = Web3Client(currentNet.rpcURL, Client());
  if(client!=null){
  Future.sync(() async {
      final newBalance = await client!.getBalance(EthereumAddress.fromHex(account));
      if(newBalance.getInWei != balance.getInWei ) {
        balance = newBalance;
      }
    }).then((value) => updateCallback.call() );
  }




  print(payload);
  }

  static Future<void> walletReconnect(BuildContext? context) async {

    // Define a session storage
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();


    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'ToNear App',
        url: 'https://walletconnect.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );
    // Subscribe to events
    connector.on('connect', (session){
      print('\nconnect\n');
      print(session);

    });
    connector.on('session_update', sessionUpdateCallback);
    connector.on('disconnect', (session){
      print('\ndisconnect\n');
      print(session);

    });


    if (!connector.connected) {

      if(session!=null) {
        account = session.accounts[0].toLowerCase();

      }

      chainId = session?.chainId;

      //sessionStorage.store(connector.session);
    }

    if (account != '' ) {
      chainId = connector.session.chainId;
      List<Network> networks = [...mNetworks.networks];
      networks.addAll(await mWallet.getListNetworks());
      try {
        currentNet = networks.firstWhere((element) => element.chainID == chainId.toString());
      }catch(e){
        mNetworks.unknownNet.name = "Unknown (Chain ID ${chainId})";
        currentNet = mNetworks.unknownNet;
      }

      client = Web3Client(currentNet.rpcURL, Client());
      //var bal =  await client.getBalance(account);
      provider = EthereumWalletConnectProvider(connector);

      //EthPrivateKey credentials = await client.credentialsFromPrivateKey(account);

      




      balance = await client!.getBalance(EthereumAddress.fromHex(account));
     // chainId = await client.getChainId();




      isSessionConnected = true;
// You can now call rpc methods. This one will query the amount of Ether you own
      //credentials = WalletConnectEthereumCredentials(provider: provider);


      if(FirebaseHelper.fcmToken!=null) {
        final res = await Server.addUser(account, FirebaseHelper.fcmToken!, await getInsta());
        print(res);
      }
      if(context!=null) {
        print('Navigation: open profile walletReconnect');
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  const Profile()),
                //(Route<dynamic> route) => false
        );
      }
      //Navigator.pop(context, "/");

      //yourContract = YourContract(address: contractAddr, client: client);
    }else{
      if(context!=null) {
        print('Navigation: open profile walletReconnect');
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  const Connector()),
        //(Route<dynamic> route) => false
      );
      }
    }

  }

  static Future<dynamic> addNetwork(Network network) async {
    String uri = connector.session.toUri();
    uri = 'metamask://' + uri;

     OnDisplayUriCallback onDisplayUri = (uri) async {
       print(uri);
       launchUrlString(uri);
     };


    onDisplayUri.call(uri);

    await Future.delayed(Duration(seconds: 5));
    var tx;


    //provider.connector.reconnect();
    try {
      tx = await provider?.connector.sendCustomRequest(
          method: 'wallet_addEthereumChain', params: [{
        'chainId': '0x${int.parse(network.chainID).toRadixString(16)}',
        'chainName': '${network.name}',
        'rpcUrls': ['${network.rpcURL}'],
        'nativeCurrency': {
          'name': '${network.coinName}',
          'symbol':'${network.coinName}',
          'decimals':18
        }
      }
      ]).then((value) =>
      chainId = connector.session.chainId
      );
      return tx;
    } catch (e) {
      print(e);
      //showToast(e.toString());

      return e.toString();
    }
  }

  static Future<dynamic> changeNetwork(Network network) async {
    String uri = connector.session.toUri();
    uri = 'metamask://' + uri;

    OnDisplayUriCallback onDisplayUri = (uri) async {
      print(uri);
      launchUrlString(uri);
    };


    onDisplayUri.call(uri);

    await Future.delayed(Duration(seconds: 5));
    var tx;


    //provider.connector.reconnect();
    try {
      tx = await provider?.connector.sendCustomRequest(
          method: 'wallet_switchEthereumChain', params: [{
        'chainId': '0x${int.parse(network.chainID).toRadixString(16)}'
      }]).then((value){

      }
      );

      await mWallet.walletReconnect(null);
      if(chainId != connector.session.chainId) {
        chainId = connector.session.chainId;
      }

      return chainId;
    }catch(e){


      switch ((e as WalletConnectException).message){
        case "Unrecognized chain ID \"0x61\". Try adding the chain using wallet_addEthereumChain first." :

          //await addNetwork(network);
          break;
        default:
          break;
      }

      print(e);
      //showToast(e.toString());

      return e.toString();
    }






  }

  static launchMetaMask(){
    String uri = connector.session.toUri();
    uri = 'metamask://'+uri;
    launch(uri);
  }

  static Future<void> walletConnect(BuildContext? context) async {

    String rpcUrl = "https://matic-mainnet.chainstacklabs.com";

    // Define a session storage
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();

    //var s = "0xc9c36ee8f6ad18c67ffd1bd1dd152dd2340d1f55";


    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'ToNear App',
        url: 'https://walletconnect.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );
    // Subscribe to events
    connector.on('connect', (session){
      print('\nconnect\n');
      print(session);

    });
    connector.on('session_update', sessionUpdateCallback);

    // Create a new session

    if (!connector.connected) {
      sessionStatus = await connector.createSession(chainId: null , onDisplayUri: (uri) => {
        print(uri),
        launch(uri)});
      chainId = sessionStatus.chainId;
      account = sessionStatus.accounts[0].toLowerCase();
      if(FirebaseHelper.fcmToken!=null) {
        final res = await Server.addUser(account, FirebaseHelper.fcmToken!,await getInsta());
        print(res);
      }

      //sessionStorage.store(connector.session);
    }





    if (account != '' ) {
      chainId = connector.session.chainId;
      List<Network> networks = [...mNetworks.networks];
      networks.addAll(await mWallet.getListNetworks());
      try {
        currentNet = networks.firstWhere((element) =>
        element.chainID == chainId.toString());
      }catch(e){
        mNetworks.unknownNet.name = "Unknown (Chain ID ${chainId})";
        currentNet = mNetworks.unknownNet;
      }





      final client = Web3Client(currentNet.rpcURL, Client());
      //var bal =  await client.getBalance(account);
      provider = EthereumWalletConnectProvider(connector);
      EthPrivateKey credentials = await client.credentialsFromPrivateKey(account);

      balance = await client.getBalance(credentials.address);

      isSessionConnected = true;
// You can now call rpc methods. This one will query the amount of Ether you own
      //credentials = WalletConnectEthereumCredentials(provider: provider);

      if(context!=null) {
        print('Navigation: open profile walletConnect');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  const Profile()),
        );
      }

      //ourContract = YourContract(address: contractAddr, client: client);
    }
  }





  static void killSession(BuildContext context) async{

    await connector.killSession();

    final res = await Server.deleteUser(account);

    await deleteTransactionHistory();

    print('kill: '+res);
    if(!connector.connected){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  const Connector()),
      );
    }
  }


  static Future<String> sendRaw() async {
    String uri = connector.session.toUri();
    uri = 'metamask://' + uri;

    OnDisplayUriCallback onDisplayUri = (uri) async {
      print(uri);
      launch(uri);
    };

    onDisplayUri.call(uri);



    try {

      final String erc1155 = await rootBundle.loadString('assets/abi/erc1155abi.json');

      final abi = DeployedContract(ContractAbi.fromJson(erc1155, 'ERC1155'),EthereumAddress.fromHex('0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656'));

      final transfer = abi.function('safeTransferFrom');

      final approval = abi.function('setApprovalForAll');

      //connector.sendCustomRequest(method: 'safeTransferFrom', params: []);

      final cred = WalletConnectEthereumCredentials(provider: provider!);


      EthPrivateKey? credentials = await client!.credentialsFromPrivateKey('0x2902121864e7ba8a0372fa5b6fd3f13712cbbb003c4098432be82b4e49e9f277');


      final trans = Transaction.callContract(contract: abi, function: transfer, parameters:[
        EthereumAddress.fromHex('0x9c4300343C501A9cF6Fe2d5c1A5197a6dF7D2Bf9'),
        EthereumAddress.fromHex('0x65EB1b6A3Ab979B45e55Ffc560ccD8E072839fb3'),
        BigInt.parse('43423942902319331396749475977823357118326845546372406946901311255413360951297'),
        BigInt.one,
        Uint8List.fromList([])
      ],
          maxGas: 100000

      );

      final hash = await provider!.sendTransaction(
        from: account,
        to: trans.to?.hex,
        data: trans.data,
        gas: trans.maxGas,
        gasPrice: trans.gasPrice?.getInWei,
        value: trans.value?.getInWei,
        nonce: trans.nonce,
      );


      // final txx = await client?.call(contract: abi, function: transfer, params:[
      //   EthereumAddress.fromHex('0x65EB1b6A3Ab979B45e55Ffc560ccD8E072839fb3'),
      //   EthereumAddress.fromHex('0x9c4300343C501A9cF6Fe2d5c1A5197a6dF7D2Bf9'),
      //   BigInt.parse('43423942902319331396749475977823357118326845546372406946901311255413360951297'),
      //   BigInt.one,
      //   Uint8List.fromList([])
      // ],
      //     sender: await credentials.extractAddress()
      // );
      final txHash = '';





      print(txHash);
      return txHash.toString();
    }catch(e){
      print(e);
      return e.toString();
    }

  }

  static Future<String> sendPayment(double amount, String receiver) async {

    String uri = connector.session.toUri();
    uri = 'metamask://' + uri;

    OnDisplayUriCallback onDisplayUri = (uri) async {
      print(uri);
      launch(uri);
    };

    onDisplayUri.call(uri);

    BigInt value = amountToBigInt(amount);




    try {
      final txHash = await provider?.sendTransaction(
          from: account,
          to: receiver,
         // data:  EthereumAddress.fromHex("0x337610d27c682E347C9cD60BD4b3b107C9d34dDd").addressBytes,
          value: amountToBigInt(amount)
      );


      print(txHash);
      return txHash.toString();
    }catch(e){
      print(e);
      return e.toString();
    }

  }
  static BigInt amountToBigInt(double amount) {
    return BigInt.from(amount * BigInt.from(pow(10, 18)).toDouble());
  }

  static updateBalance() async {

    final client = Web3Client(currentNet.rpcURL, Client());
    account = connector.session.accounts[0].toLowerCase();
    balance = await client.getBalance(EthereumAddress.fromHex(connector.session.accounts[0]));

    print(balance.getInWei);

    updateCallback.call();
  }

  static void writeTransactionToHistory({required String direction, required String from, required String me, required String net,required String amount, String coinName = 'ETH', String txHash = ''}) {
    final dbh = DbHelper();
    dbh.openDB().then((s.Database db) async{
      if(db.isOpen){
        final q = await db.insert('transactions', {
          'wallet_address_from':from,
          'wallet_address_my':me,
          'direction':direction,
          'amount':amount,
          'net_name':net,
          'coin_name':coinName,
          'date':DateFormat('MMM dd kk:mm').format(DateTime.now()),
          'tx_hash':txHash
        });

        print('tx history: '+q.toString());
        db.close();
      }
    });

  }

  static deleteTransactionHistory() {

    final dbh = DbHelper();
    dbh.openDB().then((s.Database db) async{
      if(db.isOpen){
        final q = await db.delete('transactions');
        print('tx history delete: '+q.toString());
        db.close();
      }
    });

  }

  static Future<String> getInsta() async {
    final dbh = DbHelper();
    final db = await dbh.openDB();
    if(db.isOpen){
      final user = await db.query('user_info');
      if(user.isNotEmpty){
        return user.first['instagram'].toString();
      }
    }

    return '';
  }




}