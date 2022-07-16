import 'package:drop_cap_text/drop_cap_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_application/Animations/fade_animation.dart';
import 'package:wallet_application/NFTHelper.dart';
import 'package:wallet_application/constants.dart';
import 'package:web3dart/web3dart.dart';

class NFTScreen extends StatelessWidget {
  NFTScreen({Key? key, required this.nft}) : super(key: key);

  final Asset nft;




  @override
  void initState() {

  }

  @override
  Widget build(BuildContext context) {

    return NFTPage(nft: nft);
  }



}

class NFTPage extends StatefulWidget{
  const NFTPage({Key? key, required this.nft}) : super(key: key);

  final Asset nft;
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  State<NFTPage> createState() => _NFTPageState();

}

class _NFTPageState extends State<NFTPage> {


  late Asset nft;

  List<bool> descriptionIsOpen = [false, false, false];

  @override
  void initState() {

    nft = widget.nft;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mColors.white,
      //extendBodyBehindAppBar: true,
      appBar: AppBar(
        //backgroundColor: Colors.transparent,

        backgroundColor: mColors.light,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text( nft.collectionName, style: TextStyle(color: mColors.walletColor),),
        actions: [
          openWebButton(),
          shareButton(),
        ],
      ),
      body: SingleChildScrollView(

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: FadeAnimation(
                intervalStart: 0.3,
                child: Text(
                  nft.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              margin: EdgeInsets.only(top: 0),
              child: Stack(
                children: [
                  Hero(
                    tag: nft.imageUrl,
                    child: Image.network(nft.imageUrl),
                  ),
                ],
              ),
            ),


            nft.lastSale != null ? Container(
              decoration: BoxDecoration( border: Border.all(
                  color: mColors.Gay,
                  width: 0.5
              ),
                  borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              padding: EdgeInsets.symmetric(horizontal: 0.0),
              child: FadeAnimation(
                intervalStart: 0.3,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.access_time , color: mColors.dark, size: 25),
                          Container(
                              margin: EdgeInsets.fromLTRB(8, 0, 0, 0),
                              child: Text("Last sale August 7, 2022 at 1:10am GMT+3"))
                        ],),
                    ),
                    Divider(height: 0.5,color: mColors.Gay,),
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight:Radius.circular(10),
                          ),
                          color: mColors.light
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text("Last Price", style: TextStyle(fontSize: 16, color: mColors.Gay),),
                          SizedBox(height: 10),
                          Row(

                            children: [

                              Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(borderRadius:BorderRadius.all(Radius.circular(4)),color: mColors.lightGay ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.photo_library_outlined, color: mColors.Gay, size: 18,),
                                      Text( ' x'+ nft.lastSale!['quantity']  , style:  TextStyle(color: mColors.Gay, fontSize: 16),),
                                    ],
                                  )
                              ) ,
                              SizedBox(width: 10),
                              SvgPicture.network(nft.lastSale!["payment_token"]['image_url'].toString(),
                                height: 25,
                                width: 25,
                              ),
                              SizedBox(width: 4),
                              Text(formatNumber(EtherAmount.inWei(BigInt.from( num.parse(nft.lastSale!['total_price'])/num.parse(nft.lastSale!['quantity']))).getValueInUnit(EtherUnit.ether).toStringAsFixed(18)),
                                textAlign: TextAlign.end,
                                style: TextStyle(

                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            ],
                          ),
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed:  () {},

                                style: ElevatedButton.styleFrom(shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(10.0),

                                )
                                ),
                                child:  Container(padding: EdgeInsets.all(10),child: Text("Receive",style: TextStyle(fontSize: 20),)),
                              ),
                            ],
                          ),
                        ],
                      ),

                    ),

                  ],
                ),
              ),
            ): SizedBox(
              height: 0,
            ),

            Container(
              decoration: BoxDecoration( border: Border.all(
                  color: mColors.Gay,
                  width: 0.5
              ),
                  borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              padding: EdgeInsets.symmetric(horizontal: 0.0),
              child: FadeAnimation(
                intervalStart: 0.3,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ListTile(
                      title:    Container(
                          //margin: EdgeInsets.fromLTRB(8, 0, 0, 0),
                          child: Text("Description")),
                      leading:Icon(Icons.description_outlined , color: mColors.dark, size: 25),
                    ),

                    Divider(height: 0.5,color: mColors.Gay,),
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight:Radius.circular(10),
                          ),
                          color: mColors.light
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          nft.creator!=null ?
                          Row(
                            children: [
                              Container(
                                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),

                                  child: Text("By", style: TextStyle(fontSize: 16, color: mColors.Natural),)
                              ),

                              Text(
                                nft.creator!['user']['username'] ?? nft.creator!['address'].toString().substring(2,8),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: mColors.dark,
                                    fontWeight: FontWeight.bold),),
                            ],
                          ): SizedBox(height: 10,),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: FadeAnimation(
                              intervalStart: 0.3,
                              child: Text(
                                nft.description,
                                style: TextStyle(
                                  color: mColors.Natural,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                  height: 1.3
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10,),
                        ],
                      ),

                    ),

                    Divider(height: 0.5,color: mColors.Gay,),
                    Theme(
                      data: ThemeData().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(Icons.format_list_bulleted_rounded , color: mColors.dark, size: 25),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Container(

                              margin: EdgeInsets.fromLTRB(0, 16, 0, 16),
                              child:  Container(
                                //margin: EdgeInsets.fromLTRB(8, 0, 0, 0),
                                  child: Text("About "+nft.collectionName))
                            ),

                          ],
                        ),
                        children: [ Padding(
                          padding: EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,

                            children: [
                              Divider(height: 0.5,color: mColors.Gay,),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: mColors.light
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    nft.collectionDescription!=null ?
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0,8,0,0),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: DropCapText(
                                        nft.collectionDescription!.isNotEmpty ? nft.collectionDescription.toString() : 'This collection has no description yet.',
                                        style: TextStyle(
                                            color: mColors.Natural,
                                            fontSize: 16,
                                            letterSpacing: 1,
                                            height: 1.3
                                        ),
                                        dropCap: nft.collectionImage != null ? DropCap(
                                            child: Container(
                                              margin: EdgeInsets.fromLTRB(0,0,12,12),
                                              child: ClipRRect(
                                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                                  child: Image.network(nft.collectionImage.toString(), height: 75,width: 75, fit: BoxFit.fitHeight,)
                                              ),
                                            ),
                                            width: 75,
                                            height: 75): null,

                                      ),
                                    ) : Container(
                                      margin: EdgeInsets.fromLTRB(0,8,0,0),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        "This collection has no description yet.",
                                        style: TextStyle(
                                            color: mColors.Natural,
                                            fontSize: 16,
                                            letterSpacing: 1,
                                            height: 1.3
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),

                              ),
                            ],
                          ),
                        ),
                      ],),
                    ),
                    Divider(height: 0.5,color: mColors.Gay,),
                    Theme(
                      data: ThemeData().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(Icons.apps_rounded , color: mColors.dark, size: 25),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Container(

                                margin: EdgeInsets.fromLTRB(0, 16, 0, 16),
                                child:  Container(
                                  //margin: EdgeInsets.fromLTRB(8, 0, 0, 0),
                                    child: Text("Details"))
                            ),

                          ],
                        ),
                        children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight:Radius.circular(10),
                            ),
                              color: mColors.light
                          ),

                          child: Column(

                            children: [
                              Divider(height: 0.5,color: mColors.Gay,),
                              Container(
                                padding: EdgeInsets.all(16),
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Row(

                                        children: [
                                          Text('Contract Address'),
                                          TextButton(
                                              onPressed: (){
                                                showToast("Address copied",context:context);
                                                Clipboard.setData(ClipboardData(text: nft.contractAddress));

                                              },
                                              child: Text(nft.contractAddress.substring(0,10)+"...", style: TextStyle(color: mColors.walletColor),)),
                                        ],
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Row(

                                        children: [
                                          Text('Token ID'),
                                          SelectableText(nft.tokenId.toString()),
                                        ],
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Row(

                                        children: [
                                          Text('Token Standart'),
                                          Text(nft.schema),
                                        ],
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      ),
                                    ),
                                  ],
                                ),

                              ),
                            ],
                          ),
                        )
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String formatNumber(String num) {

    while(num.endsWith('0')||num.endsWith('.')){
      num = num.substring(0,num.length-1);
    }
    return num;
  }

  Widget openWebButton() {
    final onPressed = () async {
      if(await canLaunchUrl(Uri.parse(nft.originalLink))){
        await launchUrl(Uri.parse(nft.originalLink));
      }
    };
    return IconButton(onPressed: onPressed, icon: Icon(Icons.open_in_browser, color: mColors.deepPurple));
  }

  Widget shareButton() {
    final onPressed = () async {
      await Share.share(nft.originalLink,
          subject: '',);
    };
    return IconButton(onPressed: onPressed, icon: Icon(Icons.share, color: mColors.deepPurple));
  }
}