import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/components/dialog.dart';
import 'package:study_mate_web/Views/socialView/Cache.dart';

class ChatScreen extends StatefulWidget {
  final String userID;
  final String chatID;
  final String chatTitle;
  final bool isDarkMode;

  const ChatScreen({
    super.key,
    required this.userID,
    required this.chatID,
    required this.chatTitle,
    required this.isDarkMode,
  }); // Constructor

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCache cache = DataCache();

  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    if (!cache.isMeCached()) await cache.cacheMe();
    final currentUser = cache.getCachedMe();
    if (currentUser == null) {
      PopUp(message: 'Error: User not found.');
      FirebaseAuth.instance.signOut();
      return;
    }

    if (_controller.text.isNotEmpty) {
      // Send the message to the sub-collection named by the current month
      _firestore
          .collection('AvailableChats') // Access the AvailableChats collection
          .doc(widget
              .userID) // Reference to the specific user's document (e.g., userID)
          .collection(
              'chats') // Reference to the subcollection (e.g., chat date)
          .doc(widget
              .chatID) // Reference to the specific chat (could be chat ID or timestamp)
          .collection(
              'messages') // Subcollection to store individual messages for this chat
          .add({
        'name': currentUser['Name'], // Sender's name
        'text': _controller.text, // Message text
        'createdAt':
            Timestamp.now(), // Timestamp of when the message is created
        'userId': FirebaseAuth.instance.currentUser?.uid, // ID of the sender
      });

      _controller.clear();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D24),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('AvailableChats') // Parent collection
                  .doc(widget.userID) // Chat's document (e.g., userId)
                  .collection('chats') // Date-based sub-collection or category
                  .doc(widget.chatID) // Specific chat document
                  .collection(
                      'messages') // Messages sub-collection under the specific chat
                  .orderBy('createdAt',
                      descending: false) // Order messages by 'createdAt'
                  .snapshots(),
              builder: (ctx, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chatDocs = chatSnapshot.data!.docs;
                // After messages are updated, scroll to the bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController, // Attach the controller here
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: chatDocs[index]['userId'] ==
                              FirebaseAuth.instance.currentUser?.uid
                          ? Alignment.centerRight // My messages on the right
                          : Alignment
                              .centerLeft, // Others' messages on the left
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: chatDocs[index]['userId'] ==
                                  FirebaseAuth.instance.currentUser?.uid
                              ? const Color.fromARGB(
                                  116, 136, 220, 192) // Blue for own messages
                              : const Color(
                                  0xFF4A4D56), // Gray for others' messages
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20.0),
                            topRight: const Radius.circular(20.0),
                            bottomLeft: Radius.circular(chatDocs[index]
                                        ['userId'] ==
                                    FirebaseAuth.instance.currentUser?.uid
                                ? 20.0
                                : 0),
                            bottomRight: Radius.circular(chatDocs[index]
                                        ['userId'] !=
                                    FirebaseAuth.instance.currentUser?.uid
                                ? 20.0
                                : 0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: chatDocs[index]['userId'] ==
                                  FirebaseAuth.instance.currentUser?.uid
                              ? CrossAxisAlignment
                                  .end // Right-aligned for own messages
                              : CrossAxisAlignment
                                  .start, // Left-aligned for others
                          children: <Widget>[
                            Text(
                              chatDocs[index]['name'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.0,
                              ),
                            ),
                            Text(
                              chatDocs[index]['text'],
                              style: const TextStyle(
                                color: Colors.white, // White text color
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Sent at: ${chatDocs[index]['createdAt'].toDate().toLocal().toString()}',
                              style: const TextStyle(
                                color:
                                    Colors.white60, // Light gray for timestamp
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Message input and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                        color: Colors.white), // White text color for input
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      hintStyle: const TextStyle(
                          color: Colors.white70), // Lighter hint color
                      filled: true,
                      fillColor:
                          const Color(0xFF3C434C), // Input background color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xFF4A8DFF)), // Blue send icon
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
