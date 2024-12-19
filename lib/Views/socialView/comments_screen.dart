import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../components/dialog.dart';
import 'Cache.dart'; // Ensure this path is correct

class CommentPage extends StatefulWidget {
  final String postId;

  const CommentPage({super.key, required this.postId});

  @override
  CommentPageState createState() => CommentPageState();
}

class CommentPageState extends State<CommentPage> {
  final DataCache cache = DataCache();
  DocumentSnapshot? postSnapshot;
  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> comments = []; // Store comments as a list of maps
  final TextEditingController commentController = TextEditingController();
  bool isLoading = false; // Loading indicator
  bool isCommentingEnabled = true; // State to disable comment button
  int likeCount = 0;
  bool isLiked = false;
  bool likeButtonEnable = true;

  @override
  void initState() {
    super.initState();
    fetchPost();
    fetchComments();
  }

  Future<void> fetchPost() async {
    try {
      if (cache.isMeCached()) {
        currentUser = cache.getCachedMe();
      }
      if (cache.isPostCached(widget.postId)) {
        postSnapshot = cache.getCachedPost(widget.postId);
      } else {
        postSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get();
        if (postSnapshot != null) {
          cache.cachePost(widget.postId, postSnapshot!);
        }
      }
      if (postSnapshot != null) {
        setState(() {
          likeCount = postSnapshot!['likes'] ?? 0;
          isLiked = postSnapshot!['likedBy']
                  ?.contains(FirebaseAuth.instance.currentUser?.uid) ??
              false;
        });
      }
    } catch (e) {
      PopUp(message: "Error fetching post: $e");
    }
  }

  Future<void> fetchComments() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true; // Start loading
        });
      }

      final commentSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true) // Order comments by timestamp
          .get();

      comments = commentSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (mounted) {
        PopUp(message: "Error fetching comments: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    }
  }

  Future<void> addComment() async {
    if (!cache.isMeCached()) {
      await cache.cacheMe();
      currentUser = cache.getCachedMe();
    } else {
      currentUser = cache.getCachedMe();
    }

    if (currentUser == null) {
      PopUp(message: "User data not available.");
      return;
    }

    if (commentController.text.isNotEmpty) {
      String text = commentController.text;

      // Create a new comment map
      Map<String, dynamic> newComment = {
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': currentUser!['uid'], // Get current user's UID from cache
        'userName': currentUser!['Name'], // Get current user's name from cache
      };

      // Immediately add the new comment to the local list
      setState(() {
        comments.insert(0, newComment); // Insert new comment at the top
        commentController.clear(); // Clear the text field
        isCommentingEnabled = false; // Disable commenting while processing
      });

      try {
        // Now add the comment to Firestore
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add(newComment);
      } catch (e) {
        PopUp(message: "Error adding comment: $e");
      } finally {
        setState(() {
          isCommentingEnabled = true; // Re-enable commenting
        });
      }
    }
  }

  Future<void> likePost() async {
    try {
      if (isLiked) {
        setState(() {
          likeButtonEnable = false;
          likeCount--;
          isLiked = false;
        });

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({
          'likes': FieldValue.increment(-1),
          'likedBy':
              FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid])
        });
      } else {
        setState(() {
          likeButtonEnable = false;
          likeCount++;
          isLiked = true;
        });

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({
          'likes': FieldValue.increment(1),
          'likedBy':
              FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid])
        });
      }
    } catch (e) {
      PopUp(message: "Error happend ${e.toString()}");
    } finally {
      setState(() {
        likeButtonEnable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Post Details
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postSnapshot?['userName'] ?? 'Unknown User',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      postSnapshot?['content'] ?? 'No content',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Spacer(),
                    GestureDetector(
                      onTap: likePost,
                      child: Row(
                        children: [
                          Icon(isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_off_alt),
                          const SizedBox(width: 5),
                          Text(
                            '$likeCount : ${postSnapshot?['timestamp'] != null ? postSnapshot!['timestamp'].toDate() : 'Unknown date'}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Text("hello"),
          // Comments List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator()) // Loading indicator
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentData = comments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 45),
                        child: ListTile(
                          title: Text(
                            commentData['text'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            commentData['userName'] ?? 'Anonymous',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Comment Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    enabled: isCommentingEnabled && comments.length < 50,
                    decoration: InputDecoration(
                      hintText: comments.length < 50
                          ? 'Add a comment...'
                          : 'Comments limit reached',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: addComment // Disable if commenting
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
