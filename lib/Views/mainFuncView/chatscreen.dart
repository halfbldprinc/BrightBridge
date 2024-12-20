import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _messages = [];
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Load messages with pagination
  Future<void> _loadMessages() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    Query query = _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _lastDocument = querySnapshot.docs.last;
        _messages.addAll(querySnapshot.docs.reversed);
      });
    }

    setState(() => _isLoadingMore = false);
  }

  // Send a message
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userID)
        .get();

    final currentUserName = userSnapshot.data()!['Name'];

    // Add message to Firestore
    await _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID)
        .collection('messages')
        .add({
      'name': currentUserName,
      'text': _controller.text,
      'createdAt': Timestamp.now(),
      'userId': currentUserId,
      'status': 'sent', // Mark the message as sent
    });
    _controller.clear();
    // Update 'hasNewMessage' for other users in the chat
    final chatDocRef = _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID);

    final docSnapshot = await chatDocRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('hasNewMessage')) {
        Map<String, dynamic> hasNewMessage =
            Map<String, dynamic>.from(data['hasNewMessage'] ?? {});
        hasNewMessage[widget.userID] = false;
        // Set 'hasNewMessage' flag for other users to true
        hasNewMessage.forEach((key, value) {
          if (key != currentUserId) {
            hasNewMessage[key] = true;
          }
        });

        await chatDocRef.update({'hasNewMessage': hasNewMessage});
      } else {
        // Initialize 'hasNewMessage' for the current user
        await chatDocRef.update({
          'hasNewMessage': {
            currentUserId: false, // Current user is not new
          },
        });
      }
    }

    // Update message status to "delivered"
    final messageDoc = await _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID)
        .collection('messages')
        .where('text', isEqualTo: _controller.text)
        .where('name', isEqualTo: currentUserName)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (messageDoc.docs.isNotEmpty) {
      final messageId = messageDoc.docs.first.id;
      await _updateMessageStatus(messageId, 'delivered');
    }
  }

  // Update message status
  Future<void> _updateMessageStatus(String messageId, String status) async {
    await _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID)
        .collection('messages')
        .doc(messageId)
        .update({'status': status});
  }

  // Mark messages as read for the current user
  Future<void> _markMessagesAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final chatDocRef = _firestore
        .collection('AvailableChats')
        .doc(widget.userID)
        .collection('chats')
        .doc(widget.chatID);

    final docSnapshot = await chatDocRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('hasNewMessage')) {
        Map<String, dynamic> hasNewMessage =
            Map<String, dynamic>.from(data['hasNewMessage'] ?? {});

        // Mark the current user as having read the messages
        if (hasNewMessage.containsKey(currentUserId)) {
          hasNewMessage[widget.userID] = false;
        }

        await chatDocRef.update({'hasNewMessage': hasNewMessage});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(widget.chatTitle),
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
            color: widget.isDarkMode ? Colors.white : Colors.black),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('AvailableChats')
                  .doc(widget.userID)
                  .collection('chats')
                  .doc(widget.chatID)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
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
                  controller: _scrollController,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: chatDocs[index]['userId'] ==
                              FirebaseAuth.instance.currentUser?.uid
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: chatDocs[index]['userId'] ==
                                  FirebaseAuth.instance.currentUser?.uid
                              ? (widget.isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!)
                              : (widget.isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[200]!),
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
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              chatDocs[index]['name'],
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                                fontSize: 12.0,
                              ),
                            ),
                            Text(
                              chatDocs[index]['text'],
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Sent at: ${DateFormat.yMd().add_jm().format(chatDocs[index]['createdAt'].toDate())}',
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
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
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      hintStyle: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white54
                              : Colors.black54),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
