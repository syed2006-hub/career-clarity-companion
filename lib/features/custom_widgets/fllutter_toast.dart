import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showBottomToast(String message, {Color bg = Colors.black87}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: bg,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}
