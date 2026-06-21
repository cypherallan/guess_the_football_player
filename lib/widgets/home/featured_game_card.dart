import 'package:flutter/material.dart';

class FeaturedGameCard extends StatelessWidget {
  const FeaturedGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.white, size: 50),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                'Continue Playing\nvs Recent Opponent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
