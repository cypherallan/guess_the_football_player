import 'package:flutter/material.dart';

class AnswerButtons extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const AnswerButtons({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onYes,
            child: const Text('YES'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onNo,
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }
}