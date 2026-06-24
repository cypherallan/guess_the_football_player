import 'package:flutter/material.dart';
import '../../screens/ai/ai_guess_player_screen.dart';

class AiLevelSelectionScreen extends StatelessWidget {
  const AiLevelSelectionScreen({super.key});

  // 🟢 FIXED: Removed global const constraint & fixed the icon keys
  static final List<Map<String, dynamic>> _aiTiers = [
    {
      "name": "Beginner",
      "stake": 50,
      "description": "Global superstars everyone knows. Perfect for a warm-up.",
      "color": Colors.greenAccent, // 🟢 FIXED: Changed from emeraldAccent
      "icon": Icons.child_care_rounded,
    },
    // ... rest of your tiers remain exactly the same
    {
      "name": "Easy",
      "stake": 100,
      "description":
          "High-profile modern players and household football names.",
      "color": Colors.cyanAccent,
      "icon": Icons.directions_run_rounded,
    },
    {
      "name": "Normal",
      "stake": 200,
      "description":
          "Solid starters across Europe's top 5 leagues. Requires focus.",
      "color": Colors.orangeAccent,
      "icon": Icons.sports_soccer_rounded,
    },
    {
      "name": "Hard",
      "stake": 350,
      "description":
          "Obscure stars, cult heroes, and deep-squad squad tactical selections.",
      "color": Colors.pinkAccent,
      "icon": Icons.bolt_rounded, // 🟢 FIXED
    },
    {
      "name": "Expert",
      "stake": 500,
      "description":
          "Historical legends or almost impossible profiles. True pundits only.",
      "color": Colors.redAccent,
      "icon": Icons.terminal_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'AI CHALLENGE PORTAL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.smart_toy, size: 40, color: Colors.blueAccent),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Neural Football Engine",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Select a processing difficulty tier below. High risk yields higher coin multipliers.",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tier = _aiTiers[index];
                final Color accentColor = tier["color"];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () => _navigateToGame(context, tier),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tier["icon"],
                              color: accentColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tier["name"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tier["description"],
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "STAKE",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${tier["stake"]}",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.monetization_on,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: _aiTiers.length),
            ),
          ),
        ],
      ),
    );
  }

void _navigateToGame(BuildContext context, Map<String, dynamic> tier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiGuessPlayerScreen(
          chosenLevel: tier["name"],
          chosenStake: tier["stake"],
        ),
      ),
    );
  }
}
