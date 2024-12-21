import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_mate_web/Views/socialView/newsfeed_screen.dart';
import 'Cache.dart';

class CreatePostPage extends StatefulWidget {
  final bool isDarkMode; // Received boolean for dark mode

  const CreatePostPage({super.key, required this.isDarkMode}); // Constructor

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController postController = TextEditingController();
  final DataCache cache = DataCache();
  final ValueNotifier<bool> isPosting = ValueNotifier(false);
  String errorMessage = ''; // To display error message

  @override
  void dispose() {
    postController.dispose();
    isPosting.dispose();
    super.dispose();
  }

  Future<void> createPost() async {
    if (postController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Post cannot be empty';
      });
      return;
    }

    isPosting.value = true;

    try {
      if (!cache.isMeCached()) await cache.cacheMe();
      final currentUser = cache.getCachedMe();
      if (currentUser == null) {
        FirebaseAuth.instance.signOut();
        return;
      }

      final String postId =
          FirebaseFirestore.instance.collection('posts').doc().id;
      Map<String, dynamic> newPost = {
        'content': postController.text,
        'likedBy': [],
        'userName': currentUser['Name'],
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'commentsCount': 0,
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(newPost);

      cache.cachePost(
          postId,
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .get());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => NewsFeed(isDarkMode: widget.isDarkMode)),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error creating post: $e';
      });
    } finally {
      isPosting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the passed isDarkMode value
    final isDarkMode = widget.isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black87 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final buttonColor = isDarkMode ? Colors.blueAccent : Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Consistent padding
        child: Column(
          children: [
            // Post text field inside a soft card-like container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: postController,
                maxLines: null,
                style: TextStyle(color: textColor), // Matching text color
                decoration: InputDecoration(
                  hintText: 'What is on your mind?',
                  hintStyle: TextStyle(
                      color: textColor.withOpacity(0.6)), // Faded hint color
                  border: InputBorder.none, // No border for modern look
                ),
              ),
            ),
            const SizedBox(height: 16), // Space between text field and button
            // Display error message if any
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: isPosting,
              builder: (context, isLoading, _) {
                return GestureDetector(
                  onTap: isLoading ? null : createPost,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        if (!isLoading)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Post",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
