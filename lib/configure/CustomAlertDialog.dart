import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText1;
  final String buttonText2;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  CustomAlertDialog({
    required this.title,
    required this.content,
    required this.buttonText1,
    required this.buttonText2,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF191919),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              content,
              style: TextStyle(color: Colors.white70, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(buttonText2, style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: onConfirm,
                  child: Text(buttonText1, style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
