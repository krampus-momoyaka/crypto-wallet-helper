import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TxLeadingWidget extends StatelessWidget {
  final String direction;

  const TxLeadingWidget({
    Key? key,
    required this.direction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 15, 0),
      child: direction == 'income'?
      const Icon(Icons.monetization_on_outlined, color: Colors.green, size: 30,):
      const Icon(Icons.monetization_on_outlined, color: Colors.red, size: 30,)
    );
  }
}
