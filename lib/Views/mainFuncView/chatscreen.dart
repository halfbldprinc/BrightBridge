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
  final ValueNotifier<bool> _isSendButtonEnabled =
      ValueNotifier(false); // Notifier for button state

  List<DocumentSnapshot> _messages = [];
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSendButtonState);
    _loadMessages();
  }

  void _updateSendButtonState() {
    _isSendButtonEnabled.value = _controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButtonState);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Load messages with pagination
  Future<void> _loadMessages() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
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
      _markMessagesAsRead();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    setState(() => _isLoadingMore = false);
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();

      final currentUserName = userSnapshot.data()?['Name'] ?? 'Unknown';

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
        'status': 'sent',
      });

      _controller.clear();

      final chatDocRef = _firestore
          .collection('AvailableChats')
          .doc(widget.userID)
          .collection('chats')
          .doc(widget.chatID);

      final docSnapshot = await chatDocRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          Map<String, dynamic> hasNewMessage =
              Map<String, dynamic>.from(data['hasNewMessage'] ?? {});

          hasNewMessage[currentUserId] = false;
          hasNewMessage.forEach((key, _) {
            if (key != currentUserId) hasNewMessage[key] = true;
          });

          await chatDocRef.update({'hasNewMessage': hasNewMessage});
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final chatDocRef = _firestore
          .collection('AvailableChats')
          .doc(widget.userID)
          .collection('chats')
          .doc(widget.chatID);

      final docSnapshot = await chatDocRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && currentUserId != null) {
          Map<String, dynamic> hasNewMessage =
              Map<String, dynamic>.from(data['hasNewMessage'] ?? {});

          hasNewMessage[currentUserId] = false;

          await chatDocRef.update({'hasNewMessage': hasNewMessage});
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
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

                // If there are no messages in the chat
                if (chatSnapshot.data == null ||
                    chatSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }

                final chatDocs = chatSnapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
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
                              chatDocs[index]['name'] ?? 'Unknown',
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                                fontSize: 12.0,
                              ),
                            ),
                            Text(
                              chatDocs[index]['text'] ?? '',
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              chatDocs[index]['createdAt'] != null
                                  ? 'Sent at: ${DateFormat.yMd().add_jm().format(chatDocs[index]['createdAt'].toDate())}'
                                  : 'Sent at: Unknown time',
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
                ValueListenableBuilder<bool>(
                  valueListenable: _isSendButtonEnabled,
                  builder: (context, isEnabled, child) {
                    return IconButton(
                      onPressed: isEnabled ? _sendMessage : null,
                      icon: Icon(
                        Icons.send,
                        color: isEnabled
                            ? (widget.isDarkMode ? Colors.white : Colors.black)
                            : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
