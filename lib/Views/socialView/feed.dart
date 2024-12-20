import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/Views/mainFuncView/getInvolvedB.dart';
import 'package:study_mate_web/Views/socialView/post_screen.dart';
import 'package:study_mate_web/Views/socialView/profile_screen.dart';

class NewsFeed extends StatefulWidget {
  final bool isDarkMode;
  const NewsFeed({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<NewsFeed> createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  // Fetch user posts
  Future<List<DocumentSnapshot>> fetchUserPosts() async {
    try {
      final postSnapshot =
          await FirebaseFirestore.instance.collection('posts').get();
      return postSnapshot.docs;
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      return [];
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
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchUserPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts found'));
          }

          final posts = snapshot.data!;
          return postBuilder(posts);
        },
      ),
    );
  }

  Widget postBuilder(List<DocumentSnapshot> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postId = posts[index].id;
        return PostWidget(
          postId: postId,
          isDarkMode: widget.isDarkMode,
        );
      },
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
              ProfilePageTemp(
                isDarkMode: isDarkMode,
                userID: currentUser!.uid,
                toggleDarkMode: () {
                  isDarkMode = !isDarkMode;
                },
              ),
              isDarkMode),
          _buildDrawerTile(
              Icons.star,
              'Get Involved',
              RequestChat(
                isDarkMode: isDarkMode,
              ),
              isDarkMode),
          _buildDrawerTile(Icons.message, 'Chats',
              Text("Return avainle chats without button "), isDarkMode),
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
