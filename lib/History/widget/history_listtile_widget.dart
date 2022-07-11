import 'package:flutter/material.dart';
import 'package:wallet_application/User.dart';
import '../provider/history_provider.dart';
import 'avatar_widget.dart';

class HistoryListTileWidget extends StatelessWidget {
  final bool isSelected;
  final Trx tx;
  final ValueChanged<Trx> onSelectedTx;
  final ValueChanged<Trx> onTapTx;

  const HistoryListTileWidget({
    Key? key,

    required this.isSelected,
    required this.onSelectedTx,
    required this.tx,
    required this.onTapTx
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).primaryColor;
    final style = isSelected
        ? TextStyle(
            fontSize: 18,
            color: selectedColor,
            fontWeight: FontWeight.bold,
          )
        : TextStyle(fontSize: 18);

    return ListTile(
      onTap:() => onTapTx(tx),
      //dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      // leading: TxLeadingWidget(direction: tx.direction),
      title:  Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          Expanded(child:Container(
            margin: EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: Text(
              tx.direction == "income" ? "Receive": "Send",
              style: style,
            ),
          )),

          Text( tx.amount + " "+ tx.coinName  , style: TextStyle( color: tx.direction == "income"? Colors.green:Colors.red), ),
          Container(
              margin: EdgeInsets.fromLTRB(16, 0, 4, 0),
              child: Text(tx.date,style: TextStyle(fontSize: 14),),
          )
          //Text( tx.amount , style: TextStyle(color: tx.direction == "income"? Colors.green:Colors.red))
        ],
      ),
      // subtitle: Column(
      //   crossAxisAlignment: CrossAxisAlignment.end,
      //   children: [
      //
      //   ],
      // ),
      trailing: null
          // isSelected ? Icon(Icons.check, color: selectedColor, size: 26) : null,
    );
  }
}
