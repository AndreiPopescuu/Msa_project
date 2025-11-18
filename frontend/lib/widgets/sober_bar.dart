import 'package:flutter/material.dart';

class SoberBar extends StatelessWidget {
  final double sobrietyLevel;

  const SoberBar({super.key, required this.sobrietyLevel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nivel de sobrietate: ${(sobrietyLevel * 100).toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: sobrietyLevel,
          minHeight: 20,
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Colors.grey[300],
          color: sobrietyLevel > 0.7 ? Colors.green : Colors.red,
        ),
      ],
    );
  }
}
