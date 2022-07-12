import 'package:flutter/material.dart';
import 'package:wallet_application/network.dart';

const sMainTitle = "WalletConnect";

mixin mColors {

  static const lightGray = Color(0xFFa0aec1);
  static const white = Color(0xFFFFFFFF);
  static const walletColor = Color(0xFF3B99FC);
  static const pubKeyColor = Color(0xFFE6F1FB);
  static const light = Color(0xFFf0f0ef);
  static const appBarColor = MaterialColor(0xFFf0f0ef, <int, Color>{0: Color(0xFFf0f0ef)});
  static const gold = Color(0xFFffd700);
  static const shadowGray = Color(0x30000000);
}

mixin mNetworks  {
  static Network unknownNet = Network(name: "Unknown", rpcURL: "https://mainnet.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "1",coinName: 'ETH');
  static List<Network> networks = [
     Network(name: "Ethereum Main Network", rpcURL: "https://mainnet.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "1",coinName: 'ETH'),
     Network(name: "Ropsten Test Network", rpcURL: "https://ropsten.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "3",coinName: 'ETH'),
     Network(name: "Kovan Test Network", rpcURL: "https://kovan.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "42",coinName: 'ETH'),
     Network(name: "Rinkeby Test Network", rpcURL: "https://rinkeby.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "4",coinName: 'ETH'),
     Network(name: "Goerli Test Network", rpcURL: "https://goerli.infura.io/v3/161549e6bf884455a2b80fd391302c90", chainID: "5",coinName: 'ETH'),
     Network(name: "Smart Chain - Testnet", rpcURL: "https://data-seed-prebsc-1-s1.binance.org:8545/", chainID: "97",coinName: 'BNB'),
     Network(name: "Smart Chain", rpcURL: "https://bsc-dataseed.binance.org/", chainID: "56",coinName: 'BNB')
  ];

}