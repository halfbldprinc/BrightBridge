import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Cache.dart';
import '../../components/dialog.dart';

class CreatePostPage extends StatefulWidget {
  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController postController = TextEditingController();
  final DataCache cache = DataCache();
  final ValueNotifier<bool> isPosting = ValueNotifier(false);

  @override
  void dispose() {
    postController.dispose();
    isPosting.dispose();

    super.dispose();
  }

  Future<void> createPost() async {
    if (postController.text.isEmpty) {
      PopUp(message: "Empty!  Nothing on your mind !?");
      return;
    }

    isPosting.value = true;

    try {
      if (!cache.isMeCached()) await cache.cacheMe();
      final currentUser = cache.getCachedMe();
      if (currentUser == null) {
        PopUp(message: 'Error: User not found.');
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
      if (mounted) {
        PopUp(message: "Post created successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      PopUp(message: "Error creating post: $e");
    } finally {
      isPosting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: postController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'What is on your mind?',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isPosting,
              builder: (context, isLoading, _) {
                return ElevatedButton(
                  onPressed: isLoading ? null : createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Post", style: TextStyle(fontSize: 16)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
