import 'package:flutter/material.dart';

extension AlertDialogWithdisableBackButton on AlertDialog {
  Widget disableBackButton([bool value = false]) {
    if (value) {
      return WillPopScope(
        child: this,
        onWillPop: () => Future.value(false),
      );
    }
    return this;
  }
}
