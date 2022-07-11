import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarWidget extends StatelessWidget {
  final String avatar;
  final String name;

  const AvatarWidget({
    Key? key,
    required this.avatar,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 15, 0),
      child: CircleAvatar(
          radius: 25,
          backgroundColor: avatar == "null" ? Colors.primaries[name.length] : Colors.white,

          child: avatar == "null" ? Text(name[0],
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)) :
          ClipOval(
            child: Image.file(File(avatar),
              fit: BoxFit.cover,
              width: 150,
              height: 150,
            ),
          )
        // child: ClipOval(
        //     child: Image.asset("assets/images/no-avatar.png",
        //         fit: BoxFit.scaleDown)

      ),
    );
  }
}
