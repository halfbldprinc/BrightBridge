import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/Views/mainFuncView/chatscreen.dart';
import 'package:study_mate_web/Views/mainFuncView/getInvolvedA.dart';
import 'package:study_mate_web/Views/socialView/newsfeed_screen.dart';
import 'package:study_mate_web/main.dart';

class ChatListPage extends StatefulWidget {
  final bool isDarkMode;

  const ChatListPage({super.key, required this.isDarkMode});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedDepartment = 'IT';
  bool isLoading = true;
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> acceptedChat = [];
  List<String> values = [];

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  void showRequestForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shadowColor: widget.isDarkMode ? Colors.white : Colors.black,
          backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
          title: Text(
            "Submit A Distress Call",
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white60 : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white38 : Colors.black),
                    labelText: "What Is On Your Mind?",
                    filled: true,
                    fillColor:
                        widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white38 : Colors.black),
                    labelText: "Describe It More",
                    filled: true,
                    fillColor:
                        widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  dropdownColor:
                      widget.isDarkMode ? Colors.black : Colors.white,
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value!;
                    });
                  },
                  style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black),
                  items: ["IT", "HR", "Counseling", "Other"]
                      .map((department) => DropdownMenuItem(
                            value: department,
                            child: Text(department),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

// Submit chat request using WriteBatch for optimized writes
  Future<void> submitRequest() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String chatID =
          "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
      final userDocRef =
          _firestore.collection('AvailableChats').doc(currentUser.uid);
      final chatRef = userDocRef.collection('chats').doc(chatID);

      final userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        await userDocRef.set({'createdAt': DateTime.now()});
      }

      final chatSnapshot = await chatRef.get();
      if (chatSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You have already requested help for today.")),
        );
        return;
      }

      // Using WriteBatch to group the write operations
      WriteBatch batch = _firestore.batch();

      final newChat = {
        'title': titleController.text,
        'description': descriptionController.text,
        'department': selectedDepartment,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      batch.set(chatRef, newChat);

      // Add chat to "Assistant" collection for tracking
      final assistantDocRef =
          _firestore.collection('AvailableChats').doc('Assistant');
      batch.set(
        assistantDocRef,
        {
          'marbles': FieldValue.arrayUnion(
              ["${currentUser.uid}.$chatID.${titleController.text}"]),
        },
        SetOptions(merge: true),
      );

      // Commit the batch to Firestore
      await batch.commit();

      // Update the local state for UI
      setState(() {
        chats.insert(0, {'id': chatID, ...newChat});
      });

      Navigator.pop(context); // Close the modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat request submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
          values = item.split(".");

          if (values.length >= 3) {
            var chatData = await _firestore
                .collection('AvailableChats')
                .doc(values[0]) // userId
                .collection('chats')
                .doc(values[1]) // chatId
                .get();

            if (chatData.exists) {
              tempAcceptedChats.add({
                'userID': values[0],
                'chatID': values[1],
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
            'userID': currentUser.uid,
            'id': doc.id,
            'title': data['title'] ?? 'Unknown Title',
            ...data,
          };
        }).toList();

        // Add accepted chats to the main chat list
        acceptedChat.addAll(tempAcceptedChats.map((chat) {
          return {
            'userID': chat['userID'],
            'chatID': chat['chatID'],
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
      drawer: _buildDrawer(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (chats.isNotEmpty)
                  Flexible(
                    flex: chats.isNotEmpty && acceptedChat.isEmpty ? 1 : 2,
                    child: ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chatData = chats[index];
                        final hasNewMessage =
                            chatData['hasNewMessage'] != null &&
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
                                  color:
                                      currentTheme.textTheme.bodyLarge?.color),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userID: chatData['userID'],
                                    chatID: chatData['id'],
                                    chatTitle: chatData['title'] ?? 'Chat',
                                    isDarkMode: widget.isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                Text(
                  "Accepted Chats",
                ),
                Divider(
                  thickness: 2,
                  color: currentTheme.dividerColor,
                  indent: 16,
                  endIndent: 16,
                ),
                if (acceptedChat.isNotEmpty)
                  Flexible(
                    flex: acceptedChat.isNotEmpty && chats.isEmpty ? 1 : 2,
                    child: ListView.builder(
                      itemCount: acceptedChat.length,
                      itemBuilder: (context, index) {
                        final chatData = acceptedChat[index];
                        final hasNewMessage =
                            chatData['hasNewMessage'] != null &&
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
                                  color:
                                      currentTheme.textTheme.bodyLarge?.color),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userID: chatData['userID'],
                                    chatID: chatData['chatID'],
                                    chatTitle: chatData['title'] ?? 'Chat',
                                    isDarkMode: widget.isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showRequestForm,
        backgroundColor:
            widget.isDarkMode ? Colors.blueGrey.shade700 : Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper function to check if any user has a new message
  bool _hasAnyNewMessage(Map<String, dynamic> hasNewMessage) {
    // Filter out the key specified in exceptThis
    var filteredMap = Map<String, dynamic>.from(hasNewMessage);
    filteredMap.remove(_auth.currentUser!.uid);

    // Check if any of the remaining values are true
    return filteredMap.values.any((value) => value == true);
  }

  Widget _buildDrawer(bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.blueGrey.shade800,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerTile(
              Icons.home,
              'Profile',
              MyApp(
                isDarkMode: isDarkMode,
              ),
              isDarkMode),
          _buildDrawerTile(
              Icons.star,
              'News Feed',
              NewsFeed(
                isDarkMode: isDarkMode,
              ),
              isDarkMode),
          _buildDrawerTile(Icons.star, 'Get Involved',
              MarblePage(isDarkMode: isDarkMode), isDarkMode),
          ListTile(
            leading: Icon(Icons.logout,
                color: isDarkMode ? Colors.white : Colors.black),
            title: Text(
              'Sign Out',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerTile(
      IconData icon, String title, Widget page, bool isDarkMode) {
    return ListTile(
      leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      onTap: () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
