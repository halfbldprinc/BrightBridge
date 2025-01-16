import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/Views/components/timeGetter.dart';
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

  Future<void> submitRequest() async {
    // Ensure that the user has entered all required fields
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      // Fetch the current user
      final currentUser = _auth.currentUser;

      if (currentUser == null || currentUser.uid == null) {
        throw Exception("No user logged in");
      }

      // Generate a unique chat ID based on the current date
      String chatID =
          "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

      // Reference to the user's chats collection
      final userDocRef =
          _firestore.collection('AvailableChats').doc(currentUser.uid);
      final chatRef = userDocRef.collection('chats').doc(chatID);

      // Check if the chat already exists for today
      final chatSnapshot = await chatRef.get();
      if (chatSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You have already requested help for today.")),
        );
        return;
      }

      // Prepare the new chat data
      final newChat = {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'department': selectedDepartment,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'hasNewMessage': {
          currentUser.uid: false
        }, // Initialize the hasNewMessage field
      };

      // Create a WriteBatch to perform multiple Firestore operations in one transaction
      WriteBatch batch = _firestore.batch();

      // Add the new chat to the user's collection
      batch.set(chatRef, newChat);

      // Add the chat to the "Assistant" collection for tracking
      final assistantDocRef =
          _firestore.collection('AvailableChats').doc('Assistant');
      batch.set(
        assistantDocRef,
        {
          'marbles': FieldValue.arrayUnion([
            "${currentUser.uid}.$chatID.${titleController.text.trim()}"
          ]), // Track the marble (chat) with user ID and chat ID
        },
        SetOptions(merge: true),
      );

      // Commit the batch to Firestore
      await batch.commit();

      // Update the local state for UI
      setState(() {
        chats.insert(0,
            {'id': chatID, ...newChat}); // Add the new chat to the local list
      });

      // Close the dialog and show a success message
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat request submitted successfully!")),
      );
    } catch (e) {
      // Log the error and show it to the user
      print(
          'Error submitting request: $e'); // Log the error for debugging purposes
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

      List<Map<String, dynamic>> tempAcceptedChats = [];

      final tempShot = await _firestore
          .collection('AvailableChats')
          .doc(currentUser.uid)
          .get();

      if (tempShot.exists &&
          tempShot.data() != null &&
          tempShot.data()!['acceptedMarbles'] != null) {
        List<String> acceptedMarblesList =
            List<String>.from(tempShot.data()!['acceptedMarbles']);

        for (var item in acceptedMarblesList) {
          values = item.split(".");

          if (values.length >= 3) {
            var chatData = await _firestore
                .collection('AvailableChats')
                .doc(values[0])
                .collection('chats')
                .doc(values[1])
                .get();

            if (chatData.exists) {
              tempAcceptedChats.add({
                'userID': values[0],
                'chatID': values[1],
                'id': chatData.id,
                'title': values[2],
                ...chatData.data()!,
              });
            }
          }
        }
      }

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
            'hasNewMessage': data['hasNewMessage'] ?? {},
            ...data,
          };
        }).toList();

        acceptedChat.addAll(tempAcceptedChats.map((chat) {
          return {
            'userID': chat['userID'],
            'chatID': chat['chatID'],
            'id': chat['id'],
            'title': chat['title'],
            'hasNewMessage': chat['hasNewMessage'],
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
                        final hasNewMessage = chatData['hasNewMessage'][
                                _auth.currentUser?.displayName ??
                                    _auth.currentUser?.uid] ==
                            true;

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
                        final hasNewMessage = chatData['hasNewMessage'][
                                _auth.currentUser?.displayName ??
                                    _auth.currentUser?.uid] ==
                            true;

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
      IconData icon, String title, Widget destination, bool isDarkMode) {
    return ListTile(
      leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }
}
