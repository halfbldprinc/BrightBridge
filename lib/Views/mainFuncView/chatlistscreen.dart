import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/Views/mainFuncView/chatscreen.dart';

class ChatListPage extends StatefulWidget {
  final bool isDarkMode;

  const ChatListPage({super.key, required this.isDarkMode});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> acceptedChat = [];

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      // Prepare list for accepted chats
      List<Map<String, dynamic>> tempAcceptedChats = [];

      // Fetch accepted chats by checking 'acceptedMarbles'
      final tempShot = await _firestore
          .collection('AvailableChats')
          .doc(currentUser.uid)
          .get();

      if (tempShot.exists &&
          tempShot.data() != null &&
          tempShot.data()!['acceptedMarbles'] != null) {
        // Since 'acceptedMarbles' is a List of Strings, we can iterate over it
        List<String> acceptedMarblesList =
            List<String>.from(tempShot.data()!['acceptedMarbles']);

        for (var item in acceptedMarblesList) {
          // Split the string by '.'
          List<String> values = item.split(".");

          if (values.length >= 3) {
            var chatData = await _firestore
                .collection('AvailableChats')
                .doc(values[0]) // userId
                .collection('chats')
                .doc(values[1]) // chatId
                .get();

            if (chatData.exists) {
              tempAcceptedChats.add({
                'id': chatData.id,
                'title': values[2], // Use the title from the address
                ...chatData.data()!,
              });
            }
          }
        }
      }

      // Fetch the chats belonging to the current user
      final chatQuery = await _firestore
          .collection('AvailableChats')
          .doc(currentUser.uid)
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        chats = chatQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Unknown Title',
            ...data,
          };
        }).toList();

        // Add accepted chats to the main chat list
        chats.addAll(tempAcceptedChats.map((chat) {
          return {
            'id': chat['id'],
            'title': chat['title'],
            ...chat,
          };
        }).toList());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching chats: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme =
        widget.isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title:
              Text('Chats', style: TextStyle(color: currentTheme.primaryColor)),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chats.isEmpty
                ? const Center(child: Text('No chats available'))
                : ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chatData = chats[index];
                      final hasNewMessage = chatData['hasNewMessage'] != null &&
                          _hasAnyNewMessage(chatData['hasNewMessage']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        color: currentTheme.cardColor,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            chatData['title'] ?? 'Unknown Title',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textTheme.bodyLarge?.color),
                          ),
                          subtitle: Text(
                            chatData['description'] ?? 'No description',
                            style: TextStyle(
                                color:
                                    currentTheme.textTheme.bodyMedium?.color),
                          ),
                          trailing: hasNewMessage
                              ? CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : null,
                          onTap: () {
                            // Navigate to the specific chat's messages screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  userID:
                                      _auth.currentUser!.uid, // Pass user ID
                                  chatID: chatData['id'], // Pass the chat ID
                                  chatTitle: chatData['title'] ??
                                      'Chat', // Pass chat title
                                  isDarkMode:
                                      widget.isDarkMode, // Pass theme mode
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ));
  }

  // Helper function to check if any user has a new message
  bool _hasAnyNewMessage(Map<String, dynamic> hasNewMessage) {
    return hasNewMessage.values.any((value) => value == true);
  }
}
