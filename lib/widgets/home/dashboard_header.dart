import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardHeader extends StatelessWidget {
  final User? user;

  const DashboardHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL == null
              ? const Icon(Icons.person, size: 40)
              : null,
        ),

        const SizedBox(height: 10),

        Text(
          user?.displayName ?? 'Unknown User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
