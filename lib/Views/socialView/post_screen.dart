import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comments_screen.dart';

class PostWidget extends StatefulWidget {
  final String postId;
  final bool isDarkMode;

  const PostWidget({
    super.key,
    required this.postId,
    required this.isDarkMode,
  });

  @override
  PostWidgetState createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  DocumentSnapshot? postSnapshot;
  int likeCount = 0;
  bool isLiked = false;
  bool likeButtonEnable = true;

  @override
  void initState() {
    super.initState();
    fetchPost();
  }

  Future<void> fetchPost() async {
    try {
      postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (postSnapshot != null && postSnapshot!.exists) {
        setState(() {
          likeCount = postSnapshot!['likes'] ?? 0;
          isLiked = (postSnapshot!['likedBy'] as List<dynamic>?)
                  ?.contains(FirebaseAuth.instance.currentUser?.uid) ??
              false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching post: $e");
    }
  }

  Future<void> likePost() async {
    try {
      setState(() {
        likeButtonEnable = false;
        likeCount += isLiked ? -1 : 1;
        isLiked = !isLiked;
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'likes': FieldValue.increment(isLiked ? 1 : -1),
        'likedBy': isLiked
            ? FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid])
            : FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid]),
      });
    } catch (e) {
      debugPrint("Error liking post: $e");
    } finally {
      setState(() {
        likeButtonEnable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.isDarkMode ? 0 : 4, // Shadow only in light mode
      shadowColor: Colors.black54,
      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Name
            Text(
              postSnapshot?['userName'] ?? 'Unknown User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              postSnapshot?['content'] ?? 'No content available',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Timestamp
            Text(
              'Posted on: ${postSnapshot?['timestamp'] != null ? (postSnapshot!['timestamp'] as Timestamp).toDate().toLocal().toString() : 'Unknown date'}',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.grey : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),

            // Like and Comment Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Like Button
                GestureDetector(
                  onTap: likeButtonEnable ? likePost : null,
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                        size: 20,
                        color:
                            widget.isDarkMode ? Colors.blue[300] : Colors.blue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$likeCount Likes',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Comment Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            CommentPage(postId: widget.postId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment,
                        size: 20,
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
