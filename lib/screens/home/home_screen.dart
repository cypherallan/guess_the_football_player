import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/home/dashboard_header.dart';
import '../../widgets/home/coin_balance_card.dart';
import '../../widgets/home/recent_player_card.dart';
import '../../widgets/home/game_menu_card.dart';

import '../friends/friends_screen.dart';
import '../ai/ai_guess_player_screen.dart';

import '../../core/services/auth_service.dart';

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
                  const Icon(Icons.monetization_on),
                  const SizedBox(width: 4),
                  Text(
                    "$coins",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),

          IconButton(icon: const Icon(Icons.emoji_events), onPressed: () {}),

          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendsScreen()),
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
        padding: const EdgeInsets.all(16),
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
                                title: const Text("Play 1 vs 1"),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FriendsScreen(),
                                    ),
                                  );
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

          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
