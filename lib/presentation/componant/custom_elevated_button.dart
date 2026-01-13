import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onPress;
  final IconData icon;
  final String text;
  final Color color;
  final double height;
  final double width;


  const CustomElevatedButton({
    super.key,
    required this.onPress,
    required this.icon,
    required this.text,
    required this.color,
    required this.height,
    required this.width,

  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPress, // Correctly call the callback
      icon: Icon(
        icon,
        size: 22,
        color: Colors.white, // Icon color
      ),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Text color
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding:  EdgeInsets.symmetric(horizontal: width, vertical: height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        elevation: 5, // Shadow for depth
      ),
    );
  }
}