import 'package:flutter/material.dart';

import 'main.dart';

class SnackbarService {
  static void showShackBar(String message) {
    ScaffoldMessengerState currentState = scaffoldKey.currentState!;

    currentState.showSnackBar(
      SnackBar(
        content: Container(
          child: Text(message, style: const TextStyle(fontSize: 18)),
          height: 50,
          alignment: Alignment.center,
        ),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(currentState.context).size.height - 80),
      ),
    );
  }
}
