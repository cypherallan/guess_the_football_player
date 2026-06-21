import 'package:flutter/material.dart';

class GameMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const GameMenuCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),

        child: Card(
          elevation: 5,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(icon, size: 45, color: Colors.blue),

                const SizedBox(height: 12),

                Text(
                  title,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
