import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/coin_service.dart';

class ActiveGameplay extends StatefulWidget {
  final DocumentReference matchRef;
  final CollectionReference messagesRef;
  final Map<String, dynamic> data;
  final String uid;
  final bool isAsker;
  final bool isAnswerer;
  final int score;
  final VoidCallback onStopTimers;
  final bool coinsAwarded;
  final VoidCallback onMarkCoinsAwarded;
  final CoinService coinService;

  const ActiveGameplay({
    super.key,
    required this.matchRef,
    required this.messagesRef,
    required this.data,
    required this.uid,
    required this.isAsker,
    required this.isAnswerer,
    required this.score,
    required this.onStopTimers,
    required this.coinsAwarded,
    required this.onMarkCoinsAwarded,
    required this.coinService,
  });

  @override
  State<ActiveGameplay> createState() => _ActiveGameplayState();
}

class _ActiveGameplayState extends State<ActiveGameplay> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _guessController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _guessController.dispose();
    super.dispose();
  }

  void _showGuessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Guess The Footballer"),
        content: TextField(
          controller: _guessController,
          decoration: const InputDecoration(hintText: "Enter footballer name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_guessController.text.isEmpty) return;
              widget.onStopTimers();

              await widget.messagesRef.add({
                'from': widget.uid,
                'type': 'guess',
                'text': _guessController.text.trim().toLowerCase(),
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });

              _guessController.clear();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolesLocked = widget.data['rolesLocked'] ?? false;
    final status = widget.data['status'];
    final isLockedIn = widget.data['isLockedIn'] ?? false;

    // Default to 'asker' if turn isn't set yet.
    // This ensures that as soon as the player is locked in, it's the asker's turn.
    final currentTurn = widget.data['turn'] ?? 'asker';

    if (!rolesLocked || status == 'finished') return const SizedBox.shrink();

    return Column(
      children: [
        if (widget.isAsker) ...[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              !isLockedIn
                  ? "⏳ Waiting for opponent to lock in their footballer..."
                  : (currentTurn == 'asker'
                        ? "🤔 Your Turn! Ask a question."
                        : "⏳ Waiting for opponent's response..."),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  // --- FIX 1: Only enable when locked in AND it's the Asker's turn ---
                  enabled: isLockedIn && currentTurn == 'asker',
                  decoration: InputDecoration(
                    hintText: !isLockedIn
                        ? "Locked until opponent chooses player..."
                        : (currentTurn == 'asker'
                              ? "Ask a question..."
                              : "Waiting for answer..."),
                  ),
                ),
              ),
              IconButton(
                // --- FIX 2: Disable send button icon interaction when it's not your turn ---
                icon: Icon(
                  Icons.send,
                  color: (isLockedIn && currentTurn == 'asker')
                      ? Colors.blue
                      : Colors.grey,
                ),
                onPressed: (isLockedIn && currentTurn == 'asker')
                    ? () async {
                        if (_controller.text.isEmpty) return;
                        await widget.messagesRef.add({
                          'from': widget.uid,
                          'type': 'question',
                          'text': _controller.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // --- FIX 3: Shift the turn to the answerer ---
                        await widget.matchRef.update({
                          'lastQuestionTime': FieldValue.serverTimestamp(),
                          'turn': 'answerer',
                        });
                        _controller.clear();
                        widget.onStopTimers();
                      }
                    : null, // Passing null completely disables the button press interaction
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // --- FIX 4: Only allow guesses after a player is locked in ---
              onPressed: isLockedIn ? _showGuessDialog : null,
              child: const Text("GUESS THE PLAYER"),
            ),
          ),
        ],
        if (widget.isAnswerer) ...[
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "🛡️ Your locked in player is: ${widget.data['secretPlayer'] ?? 'Not set'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (!isLockedIn) ...[
            const Text("Choose your secret footballer"),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "e.g Messi or Lionel Messi",
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.isEmpty) return;
                await widget.matchRef.update({
                  'secretPlayer': _controller.text.trim().toLowerCase(),
                  'isLockedIn': true,
                  'turn':
                      'asker', // Explicitly hands over the very first turn to Asker here
                });
                _controller.clear();
              },
              child: const Text("LOCK IN PLAYER"),
            ),
          ],
        ],
      ],
    );
  }
}
