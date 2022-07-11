import 'package:flutter/material.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/wallet.dart';

import 'network.dart';


Future<AlertDialog> buildNetworkDialog(BuildContext context) async {
  //

  List<Network> networks = [...mNetworks.networks];
  networks.addAll(await mWallet.getListNetworks());




  // set up the AlertDialog
  return AlertDialog(
    title: Text("Select Network"),
    content: Container(
      width: double.maxFinite,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: networks.length,
          itemBuilder: (context, index) {
            final net = networks[index];
            return ListTile(
              //dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              onTap : () {

                Navigator.pop(context,net);

              },
              title: Text(
                net.name,
              ),
              trailing:
              (net.chainID == mWallet.chainId.toString()) ? Icon(Icons.check, color: Colors.black, size: 26) : null,
            );
          }),
    ),
    actions: [
    ],
  );

  // show the dialog

}