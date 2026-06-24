import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/online/online_users_screen.dart';
import '../../widgets/home/dashboard_header.dart';
import '../../widgets/home/coin_balance_card.dart';
import '../../widgets/home/recent_player_card.dart';
import '../../widgets/home/game_menu_card.dart';
import 'package:guess_the_footballer/screens/matchmaking/widgets/sent_challenges_section.dart';
import '../../core/services/auth_service.dart';
import '../../screens/matchmaking/widgets/level_selection_screen.dart';
import '../../screens/ai/ai_level_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
              // 🟢 FIX: Clamping scroll physics prevents horizontal items from freezing or fighting vertical gestures
              physics: const ClampingScrollPhysics(),
              children: [
                // Card 1: Direct link to full-page level selector
                GameMenuCard(
                  title: "Play 1vs1",
                  icon: Icons.sports_soccer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LevelSelectionScreen(),
                      ),
                    );
                  },
                ),
                // Card 2: AI option broken out into its own explicit card
                GameMenuCard(
                  title: "Challenge AI",
                  icon: Icons.smart_toy,
                  onTap: () {
                    // 🟢 FIX: Route directly to the standalone AI Level page first!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiLevelSelectionScreen(),
                      ),
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
