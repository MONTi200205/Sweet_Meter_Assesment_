import 'package:flutter/material.dart';

Color BackgroundAppBar(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.white30
      : Colors.white;
}
Color Background(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.black.withOpacity(0.7)
      : Colors.white.withOpacity(0.8);
}
Color IconColor(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
}
Color BlackText(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
}
Color WhiteText(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.black87
      : Colors.white;
}
Color Tinting(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark
      ? Colors.black12
      : Colors.transparent;
}