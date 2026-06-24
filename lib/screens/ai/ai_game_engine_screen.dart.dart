import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'football_data.dart';

class AiGameEngineScreen extends StatefulWidget {
  final String currentRole;
  final String challengeLevel;
  final int challengeStake;

  const AiGameEngineScreen({
    super.key,
    required this.currentRole,
    required this.challengeLevel,
    required this.challengeStake,
  });

  @override
  State<AiGameEngineScreen> createState() => _AiGameEngineScreenState();
}

class _AiGameEngineScreenState extends State<AiGameEngineScreen> {
  late String _activeRole;
  bool _isGameOver = false;
  bool? _didHumanWin;

  late Footballer _currentFootballer;
  final TextEditingController _guessController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();

  int _currentHintIndex = 0;
  List<String> _aiLog = [];

  @override
  void initState() {
    super.initState();
    _activeRole = widget.currentRole;
    _initializeRound();
  }

  void _initializeRound() {
    _isGameOver = false;
    _didHumanWin = null;
    _currentHintIndex = 0;
    _guessController.clear();
    _hintController.clear();
    _aiLog = ["AI initialized for Level: ${widget.challengeLevel}"];
    _currentFootballer = FootballDatabase.getRandomPlayerByTier(
      widget.challengeLevel,
    );
  }

  void _checkHumanGuess() {
    String cleanGuess = _guessController.text.trim().toLowerCase();
    if (cleanGuess.isEmpty) return;

    bool isCorrect = _currentFootballer.keywords.any(
      (keyword) => cleanGuess.contains(keyword),
    );

    if (isCorrect) {
      _endGame(true);
    } else {
      setState(() {
        if (_currentHintIndex < _currentFootballer.hints.length - 1) {
          _currentHintIndex++;
          _aiLog.add(
            "Incorrect guess. AI revealed Clue #${_currentHintIndex + 1}!",
          );
        } else {
          _endGame(false);
        }
      });
      _guessController.clear();
    }
  }

  void _processAiGuess() {
    String humanHint = _hintController.text.trim().toLowerCase();
    if (humanHint.isEmpty) return;

    setState(() {
      _aiLog.add("Your Clue: \"${_hintController.text}\"");
      if (humanHint.contains("world cup") ||
          humanHint.contains("ballon") ||
          humanHint.contains("argentina")) {
        _aiLog.add("🤖 AI: 'Is it Lionel Messi?'");
        _endGame(false);
      } else {
        _aiLog.add(
          "🤖 AI: 'Hmm, that's tough. Give me another structural hint.'",
        );
      }
    });
    _hintController.clear();
  }

  void _endGame(bool humanWon) async {
    setState(() {
      _isGameOver = true;
      _didHumanWin = humanWon;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    if (humanWon) {
      int prizePool = widget.challengeStake * 2;
      await userDoc.update({'coins': FieldValue.increment(prizePool)});
    }
  }

  void _handlePlayAgain() {
    setState(() {
      _activeRole = (_activeRole == "guesser") ? "mastermind" : "guesser";
      _initializeRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          _activeRole == "guesser" ? "Mode: Guesser" : "Mode: Mastermind",
        ),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 🟢 FIXED
            children: [
              Card(
                color: const Color(0xFF334155),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tier: ${widget.challengeLevel}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Pool: ${widget.challengeStake * 2} 🪙",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isGameOver
                    ? _buildGameOverUI()
                    : (_activeRole == "guesser"
                          ? _buildGuesserUI()
                          : _buildMastermindUI()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuesserUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.smart_toy, size: 64, color: Colors.blueAccent),
        const SizedBox(height: 16),
        Text(
          "Clue #${_currentHintIndex + 1}:",
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentFootballer.hints[_currentHintIndex],
          textAlign: TextAlign.center, // 🟢 FIXED
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _guessController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Type full player name...",
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _checkHumanGuess,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text("Submit Guess"),
        ),
      ],
    );
  }

  Widget _buildMastermindUI() {
    return Column(
      children: [
        const Text(
          "Think of an obscure player matching this tier. Type clues down below to feed the AI analyzer stream.",
          textAlign: TextAlign.center, // 🟢 FIXED
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: _aiLog.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _aiLog[i],
                  style: TextStyle(
                    color: _aiLog[i].contains('🤖')
                        ? Colors.amberAccent
                        : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hintController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter a player hint...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _processAiGuess,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: Colors.orangeAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameOverUI() {
    bool won = _didHumanWin ?? false;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          won ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
          size: 80,
          color: won ? Colors.amber : Colors.redAccent,
        ),
        const SizedBox(height: 16),
        Text(
          won ? "You Won!" : "Game Over!",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "The Player was: ${_currentFootballer.name}",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _handlePlayAgain,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text("Play Again (Switch Roles)"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Exit to Menu",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
