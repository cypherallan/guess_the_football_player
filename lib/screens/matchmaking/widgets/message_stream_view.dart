import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageStreamView extends StatelessWidget {
  final CollectionReference messagesRef;
  final DocumentReference matchRef;
  final Map<String, dynamic> data;
  final String uid;
  final bool isAsker;
  final bool isAnswerer;
  final Function(bool) onTriggerTimer;
  final Function() onIncrementNoAnswer;

  const MessageStreamView({
    super.key,
    required this.messagesRef,
    required this.matchRef,
    required this.data,
    required this.uid,
    required this.isAsker,
    required this.isAnswerer,
    required this.onTriggerTimer,
    required this.onIncrementNoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.orderBy('createdAt').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        // Sync turn processing timers via frame callback side-effects safely
        if (docs.isNotEmpty) {
          final latestMessage = docs.last.data() as Map<String, dynamic>;
          if (latestMessage['type'] == 'question' && isAnswerer) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onTriggerTimer(false),
            );
          }
        }

        for (var doc in docs) {
          final mData = doc.data() as Map<String, dynamic>;
          if (mData['type'] == 'answer' &&
              mData['questionId'] != null &&
              isAsker) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onTriggerTimer(true),
            );
          }
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final msg = docs[i].data() as Map<String, dynamic>;
            final questionId = msg['questionId'] ?? docs[i].id;

            final alreadyAnswered = docs.any((m) {
              final d = m.data() as Map<String, dynamic>;
              return d['type'] == 'answer' && d['questionId'] == questionId;
            });

            String? answerGiven;
            if (alreadyAnswered) {
              final answerDoc = docs.firstWhere((m) {
                final d = m.data() as Map<String, dynamic>;
                return d['type'] == 'answer' && d['questionId'] == questionId;
              });
              answerGiven = (answerDoc.data() as Map<String, dynamic>)['text'];
            }

            // --- TYPE: GUESS ---
            if (msg['type'] == 'guess' && isAnswerer) {
              final guessId = docs[i].id;
              final secret = (data['secretPlayer'] ?? '')
                  .toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z\s]'), '')
                  .trim();
              final guessText = (msg['text'] ?? '')
                  .toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z\s]'), '')
                  .trim();
              final isCorrectGuess =
                  secret == guessText ||
                  guessText.contains(secret) ||
                  secret.contains(guessText);

              return Card(
                color: Colors.orange[100],
                child: ListTile(
                  title: Text("Opponent guessed: ${msg['text']}"),
                  subtitle: const Text("Confirm result"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: isCorrectGuess
                            ? () async {
                                await matchRef.update({
                                  'winner': data['askerUid'],
                                  'winningGuess': guessText,
                                  'status': 'finished',
                                });
                                await messagesRef.add({
                                  'type': 'guess_response',
                                  'guessId': guessId,
                                  'response': 'confirmed',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: !isCorrectGuess
                            ? () async {
                                final currentScore = data['score'] ?? 100;
                                await matchRef.update({
                                  'score': currentScore - 10,
                                });
                                await messagesRef.add({
                                  'type': 'guess_response',
                                  'guessId': guessId,
                                  'response': 'declined',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- TYPE: GUESS RESPONSE ---
            if (msg['type'] == 'guess_response' && isAsker) {
              return Card(
                color: Colors.grey.shade200,
                child: ListTile(
                  title: const Text("Your guess result"),
                  subtitle: Text(
                    msg['response'] == 'confirmed'
                        ? "Correct guess 🎉"
                        : "❌ Incorrect guess",
                  ),
                ),
              );
            }

            // --- TYPE: QUESTION ---
            if (msg['type'] == 'question') {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isAsker && alreadyAnswered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: answerGiven == "YES"
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            answerGiven!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isAnswerer)
                        alreadyAnswered
                            ? SizedBox(
                                width: 45,
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: answerGiven == "YES"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  child: Icon(
                                    answerGiven == "YES"
                                        ? Icons.check
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 45,
                                    height: 35,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () async {
                                        await messagesRef.add({
                                          'from': uid,
                                          'type': 'answer',
                                          'questionId': questionId,
                                          'text': 'YES',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                      },
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 45,
                                    height: 35,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () async {
                                        onIncrementNoAnswer();
                                        await matchRef.update({
                                          'score': (data['score'] ?? 100) - 10,
                                        });
                                        await messagesRef.add({
                                          'from': uid,
                                          'type': 'answer',
                                          'questionId': questionId,
                                          'text': 'NO',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
