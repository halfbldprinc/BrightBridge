import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_mate_web/components/dialog.dart';
import 'package:study_mate_web/Views/initialView/register_screen.dart';
import '../socialView/newsfeed_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  bool showPassword = false;
  bool _isDarkMode = false;

  Future<void> _login(BuildContext context) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      PopUp(message: 'Please fill in all fields.').show(context);
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text)) {
      PopUp(message: 'Please enter a valid email address.').show(context);
      return;
    }

    _isLoading.value = true;
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => NewsFeed(
                  isDarkMode: _isDarkMode,
                )),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        PopUp(message: 'No user found for that email.').show(context);
      } else if (e.code == 'wrong-password') {
        PopUp(message: 'Wrong password provided.').show(context);
      } else {
        PopUp(message: 'An error occurred: ${e.code}').show(context);
      }
    } catch (e) {
      PopUp(message: e.toString()).show(context);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      home: Scaffold(
        body: Stack(
          children: [
            // Background container
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.black
                    : Colors.white, // Set background based on theme
              ),
            ),
            // Form Container with Text Fields and Login Button
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100), // Space for the top icon
                      // Welcome Text (color based on theme)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Bright Bridge ",
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          "Where Bright Minds Meet to Grow.",
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.black.withOpacity(0.6)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email Field with smooth animation on focus
                            TextField(
                              controller: emailController,
                              style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                              cursorColor:
                                  _isDarkMode ? Colors.white : Colors.black,
                              decoration: InputDecoration(
                                hintText: "E-mail",
                                hintStyle: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white54
                                          : Colors.black54),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                prefixIcon: Icon(Icons.email,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Password Field with smooth animation on focus
                            TextField(
                              controller: passwordController,
                              style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                              cursorColor:
                                  _isDarkMode ? Colors.white : Colors.black,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                hintText: "Password",
                                hintStyle: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white54
                                          : Colors.black54),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                prefixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                  child: Icon(
                                    showPassword ? Icons.lock_open : Icons.lock,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Login Button with hover animation
                      ValueListenableBuilder(
                        valueListenable: _isLoading,
                        builder: (context, isLoading, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.blueGrey.withOpacity(0.7)
                                  : const Color(
                                      0xFF6C63FF), // Purple background for the button
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.blueGrey.withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : () => _login(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Register Link with smooth fade animation (color based on theme)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterPage()),
                          );
                        },
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            "Don't have an account? Register",
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Theme toggle icon positioned at top corner
            Positioned(
              top: 40,
              right: 1,
              child: IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
