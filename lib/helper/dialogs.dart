import 'package:flutter/material.dart';

class Dialogs {
  static void showSnackbar(BuildContext context, String msg, {Duration duration = const Duration(seconds: 2)}) {
    final snackBar = SnackBar(
      content: Text(
        msg,
        style: const TextStyle(
          color: Colors.white, // Text color for better visibility on a dark background
        ),
      ),
      backgroundColor: const Color(0xFF2C2C2E), // Darker background color for dark theme
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10), // Add margin to give space from the edges
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showProgressbar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Progress bar color for dark theme
        ),
      ),
      barrierDismissible: false, // Prevent closing when tapping outside
    );
  }
}
