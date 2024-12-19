import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {

  final String label;
  final VoidCallback? onTap;
  final Color color;
  const  ActionButton({super.key, required this.label, this.onTap, this.color = Colors.teal, });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return color.withOpacity(0.5);
          }
          return color;
        },
        ),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.white), // Text color
        overlayColor: WidgetStateProperty.all<Color>(const Color(0XFFF2F5D0), ),
        padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),),
        ),
        elevation: WidgetStateProperty.all<double>(5.0),
        shadowColor: WidgetStateProperty.all<Color>(Colors.black45),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.login), // Icon for the login button
          const SizedBox(width: 10), // Spacing between icon and text
          Text(label,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold,),
          ),
        ],
      ),
    );
  }
}


