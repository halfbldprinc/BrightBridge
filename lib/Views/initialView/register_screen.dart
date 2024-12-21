import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_mate_web/Views/initialView/login_screen.dart';
import 'package:study_mate_web/components/dialog.dart';
import 'package:http/http.dart' as http;

import '../socialView/newsfeed_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController textController1 = TextEditingController();
  final TextEditingController textController2 = TextEditingController();
  bool isLoading = false;
  bool _isDarkMode = false; // State for managing dark/light mode

  // User info
  String name = "";
  String surname = "";
  String pass = "";
  DateTime? dateOfBirth;
  String faculty = "";
  bool isPassword = false;
  String nationality = "";
  int role = 0;
  List<String> RoleOptions = ['To support', 'To get support'];
  List<String> FacultyOptions = [
    'Faculty of Agricultural Sciences and Technologies',
    'Faculty of Arts and Sciences ',
    'Faculty of Communication ',
    'Faculty of Dentistry ',
    'Faculty of Economics and Administrative Sciences ',
    'Faculty of Education ',
    'Faculty of Engineering ',
    'Faculty of Fine Arts, Design and Architecture ',
    'Faculty of Health Science ',
    'Faculty of Law ',
    'Faculty of Medicine',
    'Faculty of Pharmacy'
  ];
  List<String> countries = [];

  int infoCounter = 0;
  String hintForController1 = "Name";
  String hintForController2 = "Surname";
  String buttonText = "Next";
  String textToShow = "Join Bright Bridge";

  @override
  void dispose() {
    textController1.dispose();
    textController2.dispose();
    super.dispose();
  }

  String getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'network-request-failed':
        return 'Network error. Please try again later.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'An unexpected error occurred: $errorCode';
    }
  }

  Future<void> fetchCountries() async {
    final url = Uri.parse('https://restcountries.com/v3.1/all?fields=name');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<String> countryList = data
            .map<String>((country) => country['name']['common'].toString())
            .toList();
        countryList.sort();
        setState(() {
          countries = countryList;
        });
      } else {
        throw Exception(
            'Failed to load countries. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        PopUp(message: 'Failed to fetch countries. Please try again later.')
            .show(context);
      }
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void infoGetter() {
    switch (infoCounter) {
      case 0:
        if (textController1.text.isEmpty || textController2.text.isEmpty) {
          PopUp(message: "Please fill in all fields").show(context);
        } else {
          name = textController1.text;
          surname = textController2.text;
          textController1.clear();
          textController2.clear();
          fetchCountries();
          setState(() {
            infoCounter++;
            hintForController1 = "Date of Birth";
          });
        }
        break;

      case 1:
        if (dateOfBirth == null || nationality.isEmpty) {
          PopUp(message: "Please select both Date of Birth and Nationality.")
              .show(context);
        } else if (dateOfBirth!.year > 2008) {
          PopUp(message: "Make sure your date of birth is correct.")
              .show(context);
        } else {
          setState(() {
            infoCounter++;
          });
        }
        break;

      case 2:
        if (faculty.isEmpty) {
          PopUp(message: "Please fill in fit all fields").show(context);
        } else {
          setState(() {
            hintForController1 = "Email";
            hintForController2 = "Password";
            buttonText = "Register";
            isPassword = true;
            infoCounter++;
          });
        }
        break;

      case 3:
        if (textController1.text.isEmpty ||
            !isValidEmail(textController1.text) ||
            textController2.text.isEmpty) {
          PopUp(message: "Please enter a valid email and password.")
              .show(context);
        } else {
          _registerUser();
        }
        break;
    }
  }

  Future<void> _registerUser() async {
    setState(() => isLoading = true);
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: textController1.text.trim(),
        password: textController2.text,
      );
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'Name': name,
        'Surname': surname,
        'DateOfBirth': dateOfBirth?.toIso8601String(),
        'Faculty': faculty,
        'Email': textController1.text.trim(),
        'Nationality': nationality,
        'Assistant': role,
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => NewsFeed(
                  isDarkMode: _isDarkMode,
                )),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        PopUp(message: e.toString()).show(context);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // Set theme mode based on the toggle state
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
            // Form Container with Text Fields and Register Button
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          textToShow,
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
                        child: infoCounter == 1
                            ? Column(
                                children: [
                                  // Date Picker
                                  TextField(
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          dateOfBirth = pickedDate;
                                        });
                                      }
                                    },
                                    readOnly: true,
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    cursorColor: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    decoration: InputDecoration(
                                      hintText: dateOfBirth == null
                                          ? hintForController1
                                          : "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}",
                                      hintStyle: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Dropdown for Nationality
                                  SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Column(children: [
                                        DropdownButton<String>(
                                          value: nationality.isEmpty
                                              ? null
                                              : nationality,
                                          hint: Text(
                                            "Select your nationality",
                                            style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                          items: countries.map((country) {
                                            return DropdownMenuItem<String>(
                                              value: country,
                                              child: Text(country),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              nationality = newValue!;
                                            });
                                          },
                                        ),
                                      ]))
                                ],
                              )
                            : infoCounter == 2
                                ? Column(
                                    children: [
                                      //Dropdown For Department
                                      SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Column(children: [
                                            DropdownButton<String>(
                                              value: faculty.isEmpty
                                                  ? null
                                                  : faculty,
                                              hint: Text(
                                                "Faculty",
                                                style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                              items: FacultyOptions.map((fac) {
                                                return DropdownMenuItem<String>(
                                                  value: fac,
                                                  child: Text(fac),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  faculty = newValue!;
                                                });
                                              },
                                            ),
                                          ])),
                                      const SizedBox(height: 20),
                                      // Dropdown For Role
                                      SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Column(children: [
                                            DropdownButton<String>(
                                              value: RoleOptions[
                                                  role], // Map the role (int) to its string value
                                              hint: Text(
                                                "Role",
                                                style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                              items: RoleOptions.map((ro) {
                                                return DropdownMenuItem<String>(
                                                  value: ro,
                                                  child: Text(ro),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  // Update role based on the selected value
                                                  role = RoleOptions.indexOf(
                                                      newValue!);
                                                });
                                              },
                                            )
                                          ]))
                                    ],
                                  )
                                : Column(
                                    children: [
                                      // TextField 1
                                      TextField(
                                        controller: textController1,
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        cursorColor: _isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        decoration: InputDecoration(
                                          hintText: hintForController1,
                                          hintStyle: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _isDarkMode
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // TextField 2
                                      TextField(
                                        controller: textController2,
                                        obscureText: isPassword,
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        cursorColor: _isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        decoration: InputDecoration(
                                          hintText: hintForController2,
                                          hintStyle: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _isDarkMode
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
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
                      // Register Button with hover animation
                      ValueListenableBuilder(
                        valueListenable: ValueNotifier(isLoading),
                        builder: (context, isLoading, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.blueGrey.withOpacity(0.7)
                                  : const Color(0xFF6C63FF),
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
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      infoGetter();
                                    },
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
                                  : Text(
                                      buttonText,
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
                      // Register Link with smooth fade animation
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            "Already a member? Login Here ",
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
