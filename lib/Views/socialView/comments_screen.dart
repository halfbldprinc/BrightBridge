import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/dialog.dart'; // Adjust the path as needed
import 'Cache.dart'; // Ensure this path is correct

class CommentPage extends StatefulWidget {
  final String postId;
  final bool isDarkMode; // Changed to boolean

  const CommentPage(
      {super.key, required this.postId, required this.isDarkMode});

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

  // Pagination tracking
  DocumentSnapshot? lastFetchedComment;

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

      // Fetch comments from Firestore, with pagination
      QuerySnapshot commentSnapshot;

      if (lastFetchedComment == null) {
        commentSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
      } else {
        commentSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .startAfterDocument(lastFetchedComment!)
            .limit(10)
            .get();
      }

      // Add new comments to the top of the list
      List<Map<String, dynamic>> newComments = commentSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        comments.insertAll(0, newComments); // Insert new comments at the top
      });

      if (commentSnapshot.docs.isNotEmpty) {
        lastFetchedComment = commentSnapshot.docs.last;
      }
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

      // Immediately add the new comment at the top
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
      PopUp(message: "Error happened ${e.toString()}");
    } finally {
      setState(() {
        likeButtonEnable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme =
        widget.isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post Details
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            child: Card(
              color: currentTheme.cardColor, // Background color for post card
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post user name
                    Text(
                      postSnapshot?['userName'] ?? 'Unknown User',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: currentTheme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 6),
                    // Post content
                    Text(
                      postSnapshot?['content'] ?? 'No content',
                      style: TextStyle(
                          fontSize: 16,
                          color: currentTheme.textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 6),
                    const Spacer(),
                    // Like button
                    GestureDetector(
                      onTap: likePost,
                      child: Row(
                        children: [
                          Icon(isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_off_alt),
                          const SizedBox(width: 5),

                          // Like Count Text
                          Text(
                            '$likeCount  ',
                            style: TextStyle(
                              fontSize: 14,
                              color: currentTheme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          // Timestamp Text
                          Spacer(),
                          Text(
                            ' ${postSnapshot?['timestamp'] != null ? DateFormat('h:mm a, d MMM').format((postSnapshot!['timestamp'] as Timestamp).toDate()) : 'Unknown date'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: currentTheme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Comments List
          Expanded(
            child: ListView.builder(
              itemCount: comments.length +
                  1, // Add 1 to show a loading indicator at the bottom
              itemBuilder: (context, index) {
                if (index == comments.length) {
                  // Show a loading spinner at the bottom when more comments are loading
                  if (!isLoading) {
                    fetchComments(); // Only fetch more if not loading
                  }
                  return Center(
                    child: isLoading
                        ? CircularProgressIndicator()
                        : Container(), // Show only when loading
                  );
                }
                final commentData = comments[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 45),
                  color: currentTheme.cardColor,
                  child: ListTile(
                    title: Text(
                      commentData['text'],
                      style: TextStyle(
                          fontSize: 16,
                          color: currentTheme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      commentData['userName'] ?? 'Anonymous',
                      style: TextStyle(
                          color: currentTheme.textTheme.bodyMedium?.color),
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
                    enabled: isCommentingEnabled,
                    decoration: InputDecoration(
                      labelText: 'Write a comment...',
                      labelStyle: TextStyle(
                        color: currentTheme.textTheme.bodyMedium?.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
