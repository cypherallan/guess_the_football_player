import 'package:flutter/material.dart';

class BadgeCard extends StatelessWidget {
  const BadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade100,
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, size: 40),
            SizedBox(width: 10),
            Text('Bronze Badge', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
