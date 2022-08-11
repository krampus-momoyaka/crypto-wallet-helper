
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/User.dart';
import 'package:wallet_application/UserActivity.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/dbHelper.dart';

import '../provider/history_provider.dart';
import '../widget/history_listtile_widget.dart';
import '../widget/search_widget.dart';

class HistoryPage extends StatefulWidget {

  const HistoryPage({
    Key? key,
  }) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String text = '';
  List<Trx> selectedTrx = [];
  bool isRemoveEnabled = false;

  @override
  void initState() {
    super.initState();


  }

  bool containsSearchText(Trx tx) {
    final from =  tx.from;
    final textLower = text.toLowerCase();
    final historyLower = from.toLowerCase();

    return historyLower.contains(textLower);
  }

  List<Trx> getPrioritizedCountries(List<Trx> history) {
    return [
      ...List.of(selectedTrx)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HistoryProvider>(context);
    final allHistory = provider.history;
    final history = allHistory.where(containsSearchText).toList();

    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              itemBuilder: (context, index){

                Trx tx = history[index];
                final isSelected = selectedTrx.contains(tx);

                return HistoryListTileWidget(
                  tx: tx,
                  isSelected: isSelected,
                  onSelectedTx: selectTx,
                  onTapTx: tapTx,
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
      ),
    );
  }

  AppBar buildAppBar() {


    return AppBar(
      title: Text('Tx History'),
      foregroundColor: Colors.black,
      backgroundColor:mColors.appBarColor ,
      // bottom: PreferredSize(
      //   preferredSize: Size.fromHeight(60),
      //   child: SearchWidget(
      //     text: text,
      //     onChanged: (text) => setState(() => this.text = text),
      //     hintText: 'Search transaction',
      //   ),
      // ),
    );
  }

  Widget buildSelectButton(BuildContext context) {

    return Visibility(
      visible: isRemoveEnabled,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        color: mColors.light,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: StadiumBorder(),
            minimumSize: Size.fromHeight(40),
            primary: Colors.redAccent,
          ),
          child: Text(
            "Remove selected",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: submit,
        ),
      ),
    );
  }

  void tapTx(Trx tx) async  {


    final isSend =  tx.direction == "income"? false : true;
    final from = tx.from.substring(0,5) + "..."+ tx.from.substring(tx.from.length-4, tx.from.length);
    final me = tx.me.substring(0,5) + "..."+ tx.me.substring(tx.me.length-4, tx.me.length);
    AlertDialog ad =AlertDialog (
      insetPadding: EdgeInsets.all(10),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Transaction Info'),
          IconButton(onPressed: (){
            Navigator.of(context, rootNavigator: true).pop();
          }, icon: Icon(Icons.close))
        ],
      ),
      content: Column(

        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Type', style: TextStyle(color: mColors.Gay, fontSize: 13),),
              Text("Date", style: TextStyle(color: mColors.Gay, fontSize: 13),),
            ],
          ),
          Divider(color: Colors.transparent,height: 15,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(
                  isSend?"Send":"Receive",
                  style: TextStyle( fontWeight: FontWeight.bold, color: isSend?Colors.red:Colors.green,)
                )
              ),
              Text(tx.date),
            ],

          ),

          Divider( height: 40,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('To', style: TextStyle(color: mColors.Gay, fontSize: 13),),
              Text('From', style: TextStyle(color: mColors.Gay, fontSize: 13),)
            ],

          ),
          Divider(color: Colors.transparent,height: 15,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: mColors.pubKeyColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: (){
                        //Simple to use, no global configuration
                        showToast("public key copied",context:context);
                        Clipboard.setData(ClipboardData(text: isSend? tx.from: tx.me));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.transparent),
                        child: Text(isSend? from: me),
                      )
                  )
              ),
              Material(
                  color: mColors.pubKeyColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: (){
                        //Simple to use, no global configuration
                        showToast("public key copied",context:context);
                        Clipboard.setData(ClipboardData(text: isSend? tx.me: tx.from));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.transparent),
                        child: Text(isSend? me: from),
                      )
                  )
              ),
            ],
          ),
          Divider( height: 40,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tx Hash: ', style: TextStyle(color: mColors.Gay, fontSize: 13),),
              Material(
                  color: mColors.pubKeyColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: (){
                        //Simple to use, no global configuration
                        showToast("Tx Hash copied",context:context);
                        Clipboard.setData(ClipboardData(text: tx.tx));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.transparent),
                        child: Text(tx.tx.substring(0,8) + "..."+tx.tx.substring(tx.tx.length-4,tx.tx.length)),
                      )
                  )
              ),

            ],

          ),
          Divider(height: 40,),
          tx.nftName!=null&& tx.nftName!='' ?
              Row(
            //mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NFT:  ', style: TextStyle(color: mColors.Gay, fontSize: 13),),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    Flexible(
                      child: Text(
                          tx.nftName.toString(), overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: isSend?Colors.red:Colors.green,)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              :Row(
            //mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount:  ', style: TextStyle(color: mColors.Gay, fontSize: 13),),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    Flexible(
                      child: Text(
                          tx.amount, overflow: TextOverflow.ellipsis,
                          style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: isSend?Colors.red:Colors.green,)
                      ),
                    ),
                    Text(
                        ' '+tx.coinName,
                        style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: isSend?Colors.red:Colors.green,)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

    );

    showDialog(context: context, builder: (context){
      return ad;
    });
  }

  void selectTx(Trx tx) {
    final isSelected = selectedTrx.contains(tx);
    setState(() {
      isSelected
        ? selectedTrx.remove(tx)
        : selectedTrx.add(tx);

      selectedTrx.isNotEmpty
        ? isRemoveEnabled = true
        : isRemoveEnabled = false;
    });
  }

  void submit() async{
    DbHelper dbh = DbHelper();
    Database db = await dbh.openDB();
    selectedTrx.forEach((tx) {
      db.delete('transactions',where: "tx_hash = '${tx.tx}' wallet_address_from = '${tx.from}' wallet_address_my = '${tx.me}' date = '${tx.date}'");
    });

    setState(() {
      Provider.of<HistoryProvider>(context, listen: false).updateHistory();
      isRemoveEnabled = false;
    });
  }
}
