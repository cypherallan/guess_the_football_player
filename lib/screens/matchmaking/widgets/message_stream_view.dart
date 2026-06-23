import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageStreamView extends StatefulWidget {
  final CollectionReference messagesRef;
  final DocumentReference matchRef;
  final Map<String, dynamic> data;
  final String uid;
  final bool isAsker;
  final bool isAnswerer;
  final Function(bool) onTriggerTimer;
  final Function() onIncrementNoAnswer;
  final VoidCallback onStopTimers;

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
    required this.onStopTimers,
  });

  @override
  State<MessageStreamView> createState() => _MessageStreamViewState();
}

class _MessageStreamViewState extends State<MessageStreamView> {
  String? _lastProcessedQuestion;
  String? _lastProcessedAnswer;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.messagesRef
          .orderBy('createdAt', descending: false)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        final Map<String, String> answersMap = {};

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['type'] == 'answer' && data['questionId'] != null) {
            answersMap[data['questionId']] = data['text'];
          }
        }

        // ================= QUESTION TRIGGER (FIXED LOOP) =================
        if (widget.isAnswerer && docs.isNotEmpty) {
          final lastDoc = docs.last;
          final latestMessage = lastDoc.data() as Map<String, dynamic>;

          if (latestMessage['type'] == 'question') {
            final qId = lastDoc.id;

            if (_lastProcessedQuestion != qId) {
              _lastProcessedQuestion = qId;

              WidgetsBinding.instance.addPostFrameCallback(
                (_) => widget.onTriggerTimer(false),
              );
            }
          }
        }

        // ================= ANSWER TRIGGER (FIXED LOOP) =================
        if (widget.isAsker && docs.isNotEmpty) {
          final lastDoc = docs.last;
          final mData = lastDoc.data() as Map<String, dynamic>;

          if (mData['type'] == 'answer') {
            final aId = lastDoc.id;

            if (_lastProcessedAnswer != aId) {
              _lastProcessedAnswer = aId;

              WidgetsBinding.instance.addPostFrameCallback(
                (_) => widget.onTriggerTimer(true),
              );
            }
          }
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final msg = docs[i].data() as Map<String, dynamic>;
            final questionId = msg['questionId'] ?? docs[i].id;

            //CULPRIT
            final answerGiven = answersMap[questionId];
            final alreadyAnswered = answerGiven != null;

            // ================= GUESS =================
            if (msg['type'] == 'guess' && widget.isAnswerer) {
              final guessId = docs[i].id;

              final secret = (widget.data['secretPlayer'] ?? '')
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
                                await widget.matchRef.update({
                                  'winner': widget.data['askerUid'],
                                  'winningGuess': guessText,
                                  'status': 'finished',
                                });

                                await widget.messagesRef.add({
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
                                final currentScore =
                                    widget.data['score'] ?? 100;

                                await widget.matchRef.update({
                                  'score': currentScore - 10,
                                });

                                await widget.messagesRef.add({
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

            // ================= GUESS RESPONSE =================
            if (msg['type'] == 'guess_response' && widget.isAsker) {
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

            // ================= QUESTION =================
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

                      if (widget.isAsker && alreadyAnswered)
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
                            answerGiven,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (widget.isAnswerer)
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

                                      // Change this block inside your YES button onPressed:
                                      onPressed: () async {
                                        widget.onStopTimers();

                                        // 1. Add the answer message
                                        await widget.messagesRef.add({
                                          'from': widget.uid,
                                          'type': 'answer',
                                          'questionId': questionId,
                                          'text': 'YES',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                        // 2. Add this update right here to hand the turn back to the Asker!
                                        await widget.matchRef.update({
                                          'turn': 'asker',
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
                                      // Change this block inside your NO button onPressed:
                                      // Inside message_stream_view.dart -> NO Button onPressed:
                                      onPressed: () async {
                                        widget.onStopTimers();
                                        widget
                                            .onIncrementNoAnswer(); // Keep this purely for UI stat tracking if you like

                                        // REMOVED the score -10 update block from here!

                                        print("NO pressed ${DateTime.now()}");

                                        await widget.messagesRef.add({
                                          'from': widget.uid,
                                          'type': 'answer',
                                          'questionId': questionId,
                                          'text': 'NO',
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                        await widget.matchRef.update({
                                          'turn': 'asker',
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
