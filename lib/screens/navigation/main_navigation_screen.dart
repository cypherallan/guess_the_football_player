import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../friends/friends_screen.dart';
import '../challenges/challenges_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    FriendsScreen(),
    const ChallengesScreen(),
    const LeaderboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _screens[_selectedIndex]);
  }
}
