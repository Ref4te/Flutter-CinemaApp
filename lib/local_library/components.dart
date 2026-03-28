import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildButton({
  required String text,
  required Color color,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  bool isPassword = false,
  List<TextInputFormatter>? formatters,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      inputFormatters: formatters,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    ),
  );
}

void showMessage(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating, // Делает уведомление "парящим"
      duration: const Duration(seconds: 2),
    ),
  );
}