import 'package:flutter/painting.dart';

class UpgradeTextStyles {
  TextStyle? title;
  TextStyle? message;

  TextStyle? prompt;

  TextStyle? titleReleaseNotes;

  TextStyle? bodyReleaseNotes;
  UpgradeTextStyles({
    this.title,
    this.message,
    this.prompt,
    this.titleReleaseNotes,
    this.bodyReleaseNotes,
  });
}
