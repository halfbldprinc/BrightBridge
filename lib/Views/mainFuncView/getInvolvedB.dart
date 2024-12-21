// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:study_mate_web/Views/mainFuncView/chatscreen.dart';
// import 'package:study_mate_web/Views/socialView/newsfeed_screen.dart';
// import 'package:study_mate_web/Views/socialView/profile_screen.dart';

// class RequestChat extends StatefulWidget {
//   final bool isDarkMode;
//   const RequestChat({
//     super.key,
//     required this.isDarkMode,
//   });

//   @override
//   RequestChatState createState() => RequestChatState();
// }

// class RequestChatState extends State<RequestChat> {
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   String selectedDepartment = 'IT';
//   bool isLoading = false;
//   List<Map<String, dynamic>> chats = [];

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     fetchAllChats();
//   }

//   Future<void> fetchAllChats() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) {
//         throw Exception("No user logged in");
//       }

//       final chatQuery = await _firestore
//           .collection('AvailableChats')
//           .doc(currentUser.uid)
//           .collection('chats')
//           .orderBy('timestamp', descending: true)
//           .get();

//       setState(() {
//         chats = chatQuery.docs.map((doc) {
//           final data = doc.data();
//           return {
//             'id': doc.id,
//             ...data,
//           };
//         }).toList();
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching chats: ${e.toString()}')),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void showRequestForm() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
//           title: Text(
//             "Submit A Distress Call",
//             style: TextStyle(
//               color: widget.isDarkMode ? Colors.black : Colors.black,
//             ),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(
//                     labelText: "What Is On Your Mind?",
//                     filled: true,
//                     fillColor:
//                         widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: descriptionController,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     labelText: "Describe It More",
//                     filled: true,
//                     fillColor:
//                         widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   value: selectedDepartment,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedDepartment = value!;
//                     });
//                   },
//                   items: ["IT", "HR", "Counseling", "Other"]
//                       .map((department) => DropdownMenuItem(
//                             value: department,
//                             child: Text(department),
//                           ))
//                       .toList(),
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor:
//                         widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: submitRequest,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: const Text("Submit"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Submit chat request using WriteBatch for optimized writes
//   Future<void> submitRequest() async {
//     if (titleController.text.trim().isEmpty ||
//         descriptionController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all fields")),
//       );
//       return;
//     }

//     try {
//       final currentUser = _auth.currentUser;

//       if (currentUser == null) {
//         throw Exception("No user logged in");
//       }

//       String chatID =
//           "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
//       final userDocRef =
//           _firestore.collection('AvailableChats').doc(currentUser.uid);
//       final chatRef = userDocRef.collection('chats').doc(chatID);

//       final userDocSnapshot = await userDocRef.get();
//       if (!userDocSnapshot.exists) {
//         await userDocRef.set({'createdAt': DateTime.now()});
//       }

//       final chatSnapshot = await chatRef.get();
//       if (chatSnapshot.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("You have already requested help for today.")),
//         );
//         return;
//       }

//       // Using WriteBatch to group the write operations
//       WriteBatch batch = _firestore.batch();

//       final newChat = {
//         'title': titleController.text,
//         'description': descriptionController.text,
//         'department': selectedDepartment,
//         'userId': currentUser.uid,
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       batch.set(chatRef, newChat);

//       // Add chat to "Assistant" collection for tracking
//       final assistantDocRef =
//           _firestore.collection('AvailableChats').doc('Assistant');
//       batch.set(
//         assistantDocRef,
//         {
//           'marbles': FieldValue.arrayUnion(
//               ["${currentUser.uid}.$chatID.${titleController.text}"]),
//         },
//         SetOptions(merge: true),
//       );

//       // Commit the batch to Firestore
//       await batch.commit();

//       // Update the local state for UI
//       setState(() {
//         chats.insert(0, {'id': chatID, ...newChat});
//       });

//       Navigator.pop(context); // Close the modal
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Chat request submitted successfully!")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: _buildDrawer(widget.isDarkMode),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: widget.isDarkMode
//                 ? [Colors.black, Colors.grey.shade900]
//                 : [Colors.white, Colors.blueGrey.shade50],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : chats.isEmpty
//                 ? const Center(child: Text("No chat requests found."))
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: chats.length,
//                     itemBuilder: (context, index) {
//                       final chat = chats[index];
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 4,
//                         child: ListTile(
//                           title: Text(
//                             chat['title'],
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           subtitle: Text(
//                             "Department: ${chat['department']} \nSubmitted on: ${DateFormat.yMMMEd().format(chat['timestamp'].toDate())}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           tileColor: widget.isDarkMode
//                               ? Colors.grey[800]
//                               : Colors.white,
//                           leading: const Icon(
//                             Icons.chat_rounded,
//                             size: 40,
//                             color: Colors.blue,
//                           ),
//                           trailing: const Icon(Icons.arrow_forward_ios),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ChatScreen(
//                                   userID:
//                                       FirebaseAuth.instance.currentUser!.uid,
//                                   chatID: chat['id'],
//                                   chatTitle: chat['title'],
//                                   isDarkMode: widget.isDarkMode,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: showRequestForm,
//         backgroundColor:
//             widget.isDarkMode ? Colors.blueGrey.shade700 : Colors.blue,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildDrawer(bool isDarkMode) {
//     return Drawer(
//       backgroundColor: isDarkMode ? Colors.black : Colors.white,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: <Widget>[
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: isDarkMode ? Colors.grey[900] : Colors.blueGrey.shade800,
//             ),
//             child: Text(
//               'Menu',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//               ),
//             ),
//           ),
//           _buildDrawerTile(
//               Icons.home,
//               'Profile',
//               ProfilePageTemp(
//                 isDarkMode: isDarkMode,
//                 userID: FirebaseAuth.instance.currentUser!.uid,
//                 toggleDarkMode: () {
//                   isDarkMode = !isDarkMode;
//                 },
//               ),
//               isDarkMode),
//           _buildDrawerTile(Icons.feed, 'News Feed',
//               NewsFeed(isDarkMode: isDarkMode), isDarkMode),
//           _buildDrawerTile(Icons.message, 'Chats',
//               Text("Return avaible chats "), isDarkMode),
//           ListTile(
//             leading: Icon(Icons.logout,
//                 color: isDarkMode ? Colors.white : Colors.black),
//             title: Text(
//               'Sign Out',
//               style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
//             ),
//             onTap: () {
//               FirebaseAuth.instance.signOut();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   ListTile _buildDrawerTile(
//       IconData icon, String title, Widget page, bool isDarkMode) {
//     return ListTile(
//       leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
//       title: Text(
//         title,
//         style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
//       ),
//       onTap: () {
//         Navigator.pushReplacement(
//             context, MaterialPageRoute(builder: (context) => page));
//       },
//     );
//   }
// }
