import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:study_mate_web/Views/mainFuncView/chatlistscreen.dart';
import 'package:study_mate_web/Views/mainFuncView/chatscreen.dart';
import 'package:study_mate_web/Views/socialView/newsfeed_screen.dart';
import 'package:study_mate_web/main.dart'; // For animation ticker

class MarblePage extends StatefulWidget {
  final bool isDarkMode;
  const MarblePage({super.key, required this.isDarkMode});

  @override
  MarblePageState createState() => MarblePageState();
}

class MarblePageState extends State<MarblePage>
    with SingleTickerProviderStateMixin {
  final List<MarbleData> marbles = [];
  late double screenWidth;
  late double screenHeight;
  late Ticker _ticker;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        screenWidth = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height;
      });
      _fetchMarblesFromFirebase();
    });

    _ticker = Ticker((_) {
      setState(() {
        _updateMarblePositions();
      });
    });
    _ticker.start();
  }

  Future<void> _fetchMarblesFromFirebase() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('AvailableChats')
          .doc('Assistant')
          .get();

      if (snapshot.exists) {
        var marbleIds = List<String>.from(snapshot['marbles']);

        setState(() {
          marbles.clear();
          for (var id in marbleIds) {
            List<String> values = id.split(".");
            if (values.length < 2 || values[0] == currentUserId) {
              continue;
            }

            marbles.add(MarbleData(
              userid: values[0],
              chatid: values[1],
              title: values[2],
              radius: Random().nextDouble() * 30 + 40,
              xPos: Random().nextDouble() * (screenWidth - 100) + 50,
              yPos: Random().nextDouble() * (screenHeight - 100) + 50,
              dx: Random().nextDouble() * 2 - 1,
              dy: Random().nextDouble() * 2 - 1,
              color: Color((Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(1),
            ));
          }
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching marbles: $e')),
      );
    }
  }

  void _updateMarblePositions() {
    for (var marble in marbles) {
      marble.xPos += marble.dx;
      marble.yPos += marble.dy;

      // Wall collisions
      if (marble.xPos - marble.radius < 0 ||
          marble.xPos + marble.radius > screenWidth) {
        marble.dx = -marble.dx;
      }
      if (marble.yPos - marble.radius < 0 ||
          marble.yPos + marble.radius > screenHeight) {
        marble.dy = -marble.dy;
      }

      // Inter-marble collisions
      for (var other in marbles) {
        if (marble == other) continue;
        double dx = marble.xPos - other.xPos;
        double dy = marble.yPos - other.yPos;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance < marble.radius + other.radius) {
          marble.dx = -marble.dx;
          marble.dy = -marble.dy;
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void addToacceptedMarbles(String address) async {
    try {
      await FirebaseFirestore.instance
          .collection('AvailableChats')
          .doc(currentUserId)
          .set({
        'acceptedMarbles': FieldValue.arrayUnion([address]),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('AvailableChats')
          .doc('Assistant')
          .update({
        'marbles': FieldValue.arrayRemove([address]),
      });
      // Use merge to avoid overwriting the entire document
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept chat : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: marbles.map((marble) {
          return Positioned(
            left: marble.xPos - marble.radius,
            top: marble.yPos - marble.radius,
            child: GestureDetector(
              onTap: () {
                addToacceptedMarbles(
                    marble.userid + "." + marble.chatid + "." + marble.title);

                //addToacceptedMarbles(marble.userid+marble.chatid+marble.title);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatScreen(
                            chatTitle: marble.title,
                            isDarkMode: true,
                            userID: marble.userid,
                            chatID: marble.chatid)));
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: marble.radius * 2,
                    height: marble.radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: marble.color,
                    ),
                  ),
                  Text(
                    marble.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
          _buildDrawerTile(Icons.feed, 'New Feed',
              NewsFeed(isDarkMode: isDarkMode), isDarkMode),
          _buildDrawerTile(
              Icons.star,
              'Chats',
              ChatListPage(
                isDarkMode: isDarkMode,
              ),
              isDarkMode),
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

class MarbleData {
  final String userid;
  final String chatid;
  final String title;
  final double radius;
  double xPos;
  double yPos;
  double dx;
  double dy;
  final Color color;

  MarbleData({
    required this.userid,
    required this.chatid,
    required this.title,
    required this.radius,
    required this.xPos,
    required this.yPos,
    required this.dx,
    required this.dy,
    required this.color,
  });
}
