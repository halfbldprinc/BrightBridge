import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataCache {
  static final DataCache _instance = DataCache._internal();

  // Cached user data
  Map<String, dynamic>? userData;
  // Cached posts (map of post ID to DocumentSnapshot)
  Map<String, DocumentSnapshot>? userPosts = {};
  // Cached comments (map of post ID to list of DocumentSnapshots)
  Map<String, List<DocumentSnapshot>>? postComments = {};
  // Cached current user data
  Map<String, dynamic>? me; // Change to a more structured format if needed

  factory DataCache() {
    return _instance;
  }

  DataCache._internal();

  // Clear all cached user data
  void clearAllCache() {
    userData = null;
    userPosts?.clear();
    postComments?.clear();
    me = null;
  }

  // Check if current user data is cached
  bool isMeCached() {
    return me != null;
  }

  // Cache current user data
  Future<void> cacheMe() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      FirebaseAuth.instance.signOut(); // No user logged in
    }
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      me = userSnapshot.data()
          as Map<String, dynamic>; // Cache user data as a map
    } catch (e) {
      return;
    }
  }

  // Get cached current user data
  Map<String, dynamic>? getCachedMe() {
    return me;
  }

  // Check if user data is cached
  bool isUserDataCached() {
    return userData != null;
  }

  // Cache user data
  void cacheUserData(Map<String, dynamic> data) {
    userData = data;
  }

  // Get cached user data
  Map<String, dynamic>? getCachedUserData() {
    return userData;
  }

  // Check if user posts are cached
  bool isUserPostsCached() {
    return userPosts != null && userPosts!.isNotEmpty;
  }

  // Cache user posts
  void cacheUserPosts(Map<String, DocumentSnapshot> posts) {
    userPosts = posts;
  }

  // Get cached user posts as a list
  List<DocumentSnapshot> getCachedUserPosts() {
    return userPosts?.values.toList() ?? [];
  }

  // Cache a post
  void cachePost(String postId, DocumentSnapshot postSnapshot) {
    userPosts?[postId] = postSnapshot;
  }

  // Check if a specific post is cached
  bool isPostCached(String postId) {
    return userPosts?.containsKey(postId) ?? false;
  }

  // Get cached post
  DocumentSnapshot? getCachedPost(String postId) {
    return userPosts?[postId];
  }

  // Check if comments are cached for a specific post
  bool isCommentsCached(String postId) {
    return postComments?.containsKey(postId) ?? false;
  }

  // Cache comments for a specific post
  void cacheComments(String postId, List<DocumentSnapshot> comments) {
    postComments?[postId] = comments;
  }

  // Get cached comments for a specific post
  List<DocumentSnapshot> getCachedComments(String postId) {
    return postComments?[postId] ?? [];
  }
}
