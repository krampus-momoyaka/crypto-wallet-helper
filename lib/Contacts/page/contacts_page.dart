
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallet_application/User.dart';
import 'package:wallet_application/UserActivity.dart';
import 'package:wallet_application/constants.dart';
import 'package:wallet_application/dbHelper.dart';


import '../provider/contacts_provider.dart';
import '../widget/contact_listtile_widget.dart';
import '../widget/search_widget.dart';

class ContactsPage extends StatefulWidget {

  const ContactsPage({
    Key? key,
  }) : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String text = '';
  List<User> selectedContacts = [];
  bool isRemoveEnabled = false;

  @override
  void initState() {
    super.initState();


  }

  bool containsSearchText(User user) {
    final name =  user.name;
    final textLower = text.toLowerCase();
    final contactLower = name.toLowerCase();

    return contactLower.contains(textLower);
  }

  List<User> getPrioritizedCountries(List<User> contacts) {
    return [
      ...List.of(selectedContacts)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContactsProvider>(context);
    final allContacts = provider.contacts;
    final contacts = allContacts.where(containsSearchText).toList();

    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              itemCount: contacts.length,
              itemBuilder: (context, index){

                User user = contacts[index];
                final isSelected = selectedContacts.contains(user);

                return ContactListTileWidget(
                  user: user,
                  isSelected: isSelected,
                  onSelectedUser: selectUser,
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
      ),
    );
  }

  AppBar buildAppBar() {


    return AppBar(
      title: Text('Contacts'),
      foregroundColor: Colors.black,
      backgroundColor:mColors.appBarColor ,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SearchWidget(
          text: text,
          onChanged: (text) => setState(() => this.text = text),
          hintText: 'Search contact',
        ),
      ),
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

  void tapUser(User user) async{
      await Navigator.push(context, MaterialPageRoute(builder: (context)=> UserActivity(user: user)));
      Provider.of<ContactsProvider>(context, listen: false).updateContacts();
  }

  void selectUser(User user) {
    final isSelected = selectedContacts.contains(user);
    setState(() {
      isSelected
        ? selectedContacts.remove(user)
        : selectedContacts.add(user);

      selectedContacts.isNotEmpty
        ? isRemoveEnabled = true
        : isRemoveEnabled = false;
    });
  }

  void submit() async{
    DbHelper dbh = DbHelper();
    Database db = await dbh.openDB();
    selectedContacts.forEach((user) {
      db.delete('contacts',where: "wallet_address = '${user.pubKey}'");
    });

    setState(() {
      Provider.of<ContactsProvider>(context, listen: false).updateContacts();
      isRemoveEnabled = false;
    });
  }
}
