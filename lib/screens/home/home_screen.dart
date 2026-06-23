import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/online/online_users_screen.dart';
import '../../widgets/home/dashboard_header.dart';
import '../../widgets/home/coin_balance_card.dart';
import '../../widgets/home/recent_player_card.dart';
import '../../widgets/home/game_menu_card.dart';
import 'package:guess_the_footballer/screens/matchmaking/widgets/sent_challenges_section.dart';
import '../friends/friends_screen.dart';
import '../ai/ai_guess_player_screen.dart';
import '../../core/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Method to display your dynamic high-stakes levels selection panel
  void _showLevelSelectionBottomSheet(BuildContext context) {
    final tiers = [
      {'name': 'Beginner', 'stake': 50, 'color': Colors.green},
      {'name': 'Easy', 'stake': 100, 'color': Colors.blue},
      {'name': 'Normal', 'stake': 200, 'color': Colors.orange},
      {'name': 'Hard', 'stake': 350, 'color': Colors.red},
      {'name': 'Expert', 'stake': 500, 'color': Colors.purple},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Challenge Level",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Both players stake entry coins. Winner takes the pool!",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...tiers.map((tier) {
                  final name = tier['name'] as String;
                  final stake = tier['stake'] as int;
                  final color = tier['color'] as Color;

                  return Card(
                    color: const Color(0xFF334155),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Icon(Icons.shield, color: color, size: 30),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        "Stake: $stake coins  |  Pool: ${stake * 2} coins",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      // Inside home_screen.dart -> _showLevelSelectionBottomSheet -> Card ListTile onTap:
                      onTap: () {
                        Navigator.pop(context); // Close selection sheet

                        // Open Friends Screen, passing the chosen stakes configuration along
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FriendsScreen(
                              challengeLevel: name,
                              challengeStake: stake,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Guess The Footballer'),
        centerTitle: true,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final coins = data?['coins'] ?? 1000;

              return Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    "$coins",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
          IconButton(icon: const Icon(Icons.emoji_events), onPressed: () {}),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isOnline', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final onlineUsers = snapshot.hasData
                  ? snapshot.data!.docs
                        .where((doc) => doc.id != currentUid)
                        .toList()
                  : [];

              final bool isAnyoneOnline = onlineUsers.isNotEmpty;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.people, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnlineUsersScreen(),
                        ),
                      );
                    },
                  ),
                  if (isAnyoneOnline)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text(
                  "Game Menu",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("How to Play"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About Game"),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                await AuthService().signOut();
              },
            ),
          ],
        ),
      ),
      // 🟢 FIX: We use AlwaysScrollableScrollPhysics to force scrolling capability even on short screens
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          40,
        ), // Added bottom padding so content isn't clipped
        children: [
          DashboardHeader(user: user),
          const SizedBox(height: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final coins = data?['coins'] ?? 1000;
              return CoinBalanceCard(coins: coins);
            },
          ),
          const SizedBox(height: 20),
          const RecentPlayerCard(),
          const SentChallengesSection(),
          const SizedBox(height: 25),
          const Text(
            "Quick Actions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              // 🟢 FIX: Added bouncing physics to the horizontal cards so they don't fight the vertical scroll container
              physics: const BouncingScrollPhysics(),
              children: [
                GameMenuCard(
                  title: "New Game",
                  icon: Icons.sports_soccer,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: const Text("Play 1 vs 1 (Online)"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showLevelSelectionBottomSheet(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.smart_toy),
                                title: const Text("Challenge AI"),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AiGuessPlayerScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                GameMenuCard(
                  title: "Leaderboard",
                  icon: Icons.leaderboard,
                  onTap: () {},
                ),
                GameMenuCard(
                  title: "Challenges",
                  icon: Icons.flag,
                  onTap: () {},
                ),
                GameMenuCard(
                  title: "Get Coins",
                  icon: Icons.monetization_on,
                  onTap: () {},
                ),
                GameMenuCard(
                  title: "Statistics",
                  icon: Icons.bar_chart,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
