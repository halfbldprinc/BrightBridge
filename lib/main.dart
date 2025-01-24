import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/Views/components/timeGetter.dart';
import 'package:study_mate_web/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:study_mate_web/Views/initialView/login_screen.dart';
import 'package:study_mate_web/Views/socialView/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    //
  }
  await AppTime.fetchCurrentTime();

  runApp(MyApp(
    isDarkMode: false,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  //theme value and function
  bool _isDarkMode = false;
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent, // AppBar removed
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        iconTheme:
            IconThemeData(color: Colors.black87), // Light mode icon color
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Dark mode icon color
        fontFamily: 'Roboto',
      ),
      title: 'BrightBridge ',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ProfilePageTemp(
                isDarkMode: _isDarkMode,
                toggleDarkMode: _toggleDarkMode,
                userID: FirebaseAuth.instance.currentUser!.uid);
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error.toString()}'),
              ),
            );
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
