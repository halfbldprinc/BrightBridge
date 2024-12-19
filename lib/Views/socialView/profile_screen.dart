import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:study_mate_web/Views/socialView/feed.dart';
import 'package:study_mate_web/Views/mainFuncView/getInvolvedB.dart';
import 'package:study_mate_web/Views/mainFuncView/getInvolvedA.dart';
import 'package:study_mate_web/Views/socialView/post_screen.dart';

class ProfilePageTemp extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;
  final String userID; // Added userID to pass to fetch data

  const ProfilePageTemp(
      {super.key,
      required this.isDarkMode,
      required this.toggleDarkMode,
      required this.userID});

  @override
  ProfilePageTempState createState() => ProfilePageTempState();
}

class ProfilePageTempState extends State<ProfilePageTemp> {
  TextEditingController aboutMeController = TextEditingController();

  bool editAboutMe = false;
  bool editPics = false;
  String imageUrl = '';
  Map<String, dynamic> userData = {};
  List<DocumentSnapshot> userPosts = [];
  List<String> privateImageUrl = [];
  List<String> privateImageNames = [];
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();

      if (!userSnapshot.exists) throw Exception("User not found");

      setState(() {
        userData = userSnapshot.data()!;
        aboutMeController.text = userData['AboutMe'] ?? '';
        privateImageNames = userData['Images'] is List
            ? List<String>.from(userData['Images'])
            : [];
      });
      fetchPrivateImage();
    } catch (e) {
      // Handle any errors

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to fetch user data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchPrivateImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance.ref(userData['ImageUrl']);
        final fetchedImageUrl = await ref.getDownloadURL();
        List<String> urls = [];
        for (var fileName in privateImageNames) {
          String path = widget.userID + '/' + fileName;

          final storageRef = FirebaseStorage.instance.ref().child(path);
          final url = await storageRef
              .getDownloadURL(); // Fetch the download URL for each file
          urls.add(url); // Add the URL to the list
        }

        // Update the UI with the list of URLs
        setState(() {
          imageUrl = fetchedImageUrl;
          privateImageUrl =
              urls; // Assuming 'privateImageUrl' is already defined
        });
      }
    } catch (e) {
      // Catch specific errors if needed, otherwise show the generic error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching private images: $e'),
          backgroundColor: Colors.red, // Error color
        ),
      );
    }
  }

  Future<List<DocumentSnapshot>> fetchUserPosts() async {
    try {
      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.userID)
          .get();

      return postSnapshot.docs; // Return the fetched list
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  Future<void> updateUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();

      if (!userSnapshot.exists) throw Exception("User not found");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .update({
        'AboutMe': aboutMeController.text,
      });
    } catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        //
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [
        //         Color(0xFFF05527), // Orange
        //         Color(0xFF882138), // Deep Red
        //         Color(0xFFB11423), // Maroon
        //       ],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        // ),
        //
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleDarkMode, // Toggle dark mode
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section (Profile Picture and Info)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  // Profile Pic Section
                  height: 250,
                  decoration: BoxDecoration(
                    // image: DecorationImage(
                    //     image: AssetImage('assets/img/CIU.png'),
                    //     fit: BoxFit.cover),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF05527), // Orange
                        Color(0xFF882138), // Deep Red
                        Color(0xFFB11423), // Maroon
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(
                      6), // Padding around the avatar to show the border
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // Make the container circular
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 238, 76, 27),
                        Color.fromARGB(255, 167, 12, 45),
                        Color.fromARGB(255, 181, 4, 21),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            //function to open it bigger or Edit if user.id = currentUser.id
                          },
                          child: CircleAvatar(
                            radius: 80,
                            backgroundImage: NetworkImage(imageUrl),
                            backgroundColor: Colors.transparent,
                          ))
                      : CircularProgressIndicator(),
                ),
                Positioned(
                  top: 210,
                  child: Text(
                    userData.isNotEmpty ? userData['Name'] : "Loading...",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Merriweather',
                    ),
                  ),
                )
              ],
            ),

            // Profile Info Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 6),
                  Text(
                    userData.isNotEmpty ? userData['Email'] : "Loading...",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    userData.isNotEmpty ? userData['Faculty'] : "Loading...",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userData.isNotEmpty
                        ? "Age: ${userData['Age']}"
                        : "Loading...",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userData.isNotEmpty
                        ? "${userData['Nationality']}"
                        : "Loading...",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // About Me Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bio ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Display text or text field based on editAboutMe
                      editAboutMe
                          ? Expanded(
                              child: TextField(
                                controller: aboutMeController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: "Enter details about yourself...",
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            )
                          : Expanded(
                              child: Text(
                                aboutMeController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                      IconButton(
                        icon: Icon(
                          editAboutMe ? Icons.check : Icons.edit,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            editAboutMe = !editAboutMe;
                            if (!editAboutMe) {
                              updateUserData();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //private pic section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Pics",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Spacer(),
                      editPics
                          ? IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.add_a_photo,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ))
                          : Spacer(), // Adds flexible space between Text and IconButton
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          editPics ? Icons.check : Icons.edit,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            editPics = !editPics;
                            if (!editPics) {
                              // Call function to get or delete
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                      height: privateImageUrl.isEmpty
                          ? 0
                          : privateImageUrl.length <= 2
                              ? MediaQuery.of(context).size.height / 4
                              : MediaQuery.of(context).size.height / 2,
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: privateImageUrl.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                              onTap: () {
                                // Implement functionality to view the image in full size
                              },
                              child: Stack(
                                children: [
                                  // Image container
                                  Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                            privateImageUrl[index]),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  // Icon buttons for upload and delete

                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: editPics
                                        ? IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {}
                                            // => deleteImage(privateImageNames[index]),
                                            )
                                        : SizedBox(),
                                  ),
                                ],
                              ));
                        },
                      )),
                ],
              ),
            ),

            //posts
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Posts",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.add,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ))
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                      height: MediaQuery.of(context).size.height / 2,
                      child: FutureBuilder<List<DocumentSnapshot>>(
                        future:
                            fetchUserPosts(), // Call the method to fetch posts as a Future
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No posts found'));
                          }

                          final posts = snapshot.data!;
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
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
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
              Icons.feed,
              'News Feed',
              NewsFeed(
                isDarkMode: isDarkMode,
              ),
              isDarkMode),
          _buildDrawerTile(
              Icons.star,
              'Get Involved',
              Text('Return Avaible Chats Whitout Request Button'),
              // RequestChat(
              //   isDarkMode: isDarkMode,
              // ),
              isDarkMode),
          _buildDrawerTile(
              Icons.message,
              'Chats',
              MarblePage(
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
