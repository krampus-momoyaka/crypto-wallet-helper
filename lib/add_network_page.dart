
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/constants.dart';
import 'package:flutter/material.dart';
import 'package:wallet_application/dbHelper.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'network.dart';

class AddNetworkPage extends StatefulWidget {
  const AddNetworkPage({Key? key}) : super(key: key);

  @override
  State<AddNetworkPage> createState() => _AddNetworkPageState();

}

class _AddNetworkPageState extends State<AddNetworkPage> {

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  String rpc = "";
  String chainId = "";
  String netName = "Private Network";
  String coinName = "ETH";

  void validator() async{
    if(globalKey.currentState!.validate()){


      try {
        final client = Web3Client(rpc, Client());

        final newChain = await client.getChainId();
        if(newChain.toString() == chainId){
          
          
          print("Validated");

          final s = await saveNewNetwork(Network(name: netName.isNotEmpty? netName:"Private Network",rpcURL: rpc,chainID: chainId,coinName: coinName.isNotEmpty? coinName: "ETH"));

          print(s);
          showToast(s, context: context);
          if(s=="Network Add Success"){

            Navigator.pop(context);
          }

        }else{
          print("Chain ID not match");
          showToast("The endpoint returned a different chain ID : ${newChain} ", context: context);
        }

      }catch(e){
        print(e);
      }
    }else{
      print("Not Validated");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: buildAppBar(),
      body: SingleChildScrollView(
        child: Form(
          key: globalKey,
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 15,horizontal: 15),
                child: Text(
                  "New RPC Newtwork",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
                child: Text(

                  "Add new network from your wallet to work with this App.",
                  style: TextStyle(fontSize: 16),
                  //textAlign: TextAlign.center,
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
                  child: buildInput("Network Name (optional)", false)
              ),
              Container(
                  margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
                  child: buildInput("RPC Url", true)
              ),

              Container(
                margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
                child: buildInput("Chain ID", true)
              ),
              Container(
                  margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15),
                  child: buildInput("Coin Name (optional)", false)
              ),

              Center(
                child: ElevatedButton(
                  onPressed: (){
                    validator();
                  },
                  child: Text("Add Network"),
                ),
              )


            ],
          ),
        ),
      ),
    );
  }


  AppBar buildAppBar() {
  return AppBar(
      title: Text('Add Network'),
      foregroundColor: Colors.black,
      backgroundColor: mColors.appBarColor ,
    );
  }

  Widget buildInput(String title, bool isCheckErrors) {

    return Center(
      child: TextFormField(
        autovalidateMode: isCheckErrors? AutovalidateMode.onUserInteraction: null,
        keyboardType: title == "Chain ID" ? TextInputType.number:null,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: title
        ),
        validator: (value){

          if(!isCheckErrors) {
            if(value!=null){
              if(title == "Coin Name (optional)"){
                coinName = value;
              }else{
                netName = value;
              }
            }

            return null;
          }

          if(value==null && title == "RPC Url") return "URLs require the appropriate HTTPS prefix";

          if(value!=null && title == "RPC Url") {
            if(value.startsWith("https", 0)){
              rpc = value;
              return null;
            } else return "URLs require the appropriate HTTPS prefix";
          }

          if(value=="" && title == "Chain ID") return "The chain ID is required. \nIt must match the chain ID returned by the network. \nYou can enter a decimal number";

          if(value!="" && title =="Chain ID") {
            chainId = value!;
            return null;
          }


        },
      ),
    );

  }




}

Future<String> saveNewNetwork(Network network) async {
  if(mNetworks.networks.any((element) => network.chainID == element.chainID)){
    return "Default Network";
  }

  DbHelper dbh = DbHelper();
  Database db = await dbh.openDB();

  final c = await db.query('networks',where: "chain_id = ?", whereArgs: [network.chainID]);

  int result = 0;
  if(c.isNotEmpty) {
    result = await db.rawUpdate("UPDATE networks SET net_name = ? ,rpc_url = ? ,chain_id = ?, coin_name = ? WHERE chain_id = ?",
        [network.name,network.rpcURL,network.chainID, network.coinName, network.chainID]
    );
  }else{
    result = await db.rawInsert("INSERT INTO networks(net_name,rpc_url,chain_id,coin_name) VALUES (?,?,?,?)",
        [network.name,network.rpcURL,network.chainID, network.coinName]
    );
  }

  db.close();
  if(result>0) return "Network Add Success";
  return "Network Add Fail";
}







