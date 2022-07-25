import 'package:flutter/material.dart';
import 'package:wallet_application/User.dart';
import 'avatar_widget.dart';

class ContactListTileWidget extends StatelessWidget {
  final bool isSelected;
  final User user;
  final ValueChanged<User> onSelectedUser;
  final ValueChanged<User> onTapUser;

  const ContactListTileWidget({
    Key? key,

    required this.isSelected,
    required this.onSelectedUser,
    required this.user,
    required this.onTapUser
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
      //dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      onTap : () => onTapUser(user),
      onLongPress: () => onSelectedUser(user),
      leading: AvatarWidget(avatar: user.avatar,name :user.name),
      title: Text(
        user.name,
        style: style,
      ),
      subtitle: Container(padding: EdgeInsets.fromLTRB(0, 8, 0, 0),child: Text(user.pubKey.substring(0,6)+'...' + user.pubKey.substring(user.pubKey.length-4, user.pubKey.length),style: TextStyle(overflow: TextOverflow.ellipsis),)),
      trailing:
          isSelected ? Icon(Icons.check, color: selectedColor, size: 26) : null,
    );
  }
}
