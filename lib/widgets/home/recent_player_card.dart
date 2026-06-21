import 'package:flutter/material.dart';

class RecentPlayerCard extends StatelessWidget {
  const RecentPlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),

        title: const Text(
          "Continue Playing",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: const Text("Last opponent: ABC"),

        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () {},
      ),
    );
  }
}
