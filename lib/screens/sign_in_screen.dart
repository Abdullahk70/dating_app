import 'package:dating_app_dashboard/constants/constants.dart';
import 'package:dating_app_dashboard/models/app_model.dart';
import 'package:dating_app_dashboard/screens/dashboard.dart';
import 'package:dating_app_dashboard/widgets/app_logo.dart';
import 'package:dating_app_dashboard/widgets/default_button.dart';
import 'package:dating_app_dashboard/widgets/default_card_border.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dating_app_dashboard/widgets/show_scaffold_msg.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    requestPermissionAndSaveToken();
    super.initState();
  }

  Future<void> requestPermissionAndSaveToken() async {
    try {
      // Request notification permission
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Retrieve the FCM token
        String? token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          setState(() {
            FCMTOKEN = token;
          });
          print('FCM Token: $token');
        } else {
          print('Failed to retrieve FCM token.');
        }
      } else {
        print('Notification permission denied.');
      }
    } catch (e) {
      print('Error requesting permission or retrieving token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 30.0),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Card(
              shape: defaultCardBorder(),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    /// App logo
                    const AppLogo(),
                    const SizedBox(height: 10),

                    /// App name
                    const Text(APP_NAME,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    const Text("Sign in with your username and password",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 22),

                    /// Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          /// Username field
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                labelText: "Username",
                                hintText: "Enter your username",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                prefixIcon: const Icon(Icons.person_outline)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (username) {
                              // Basic validation
                              if (username?.isEmpty ?? true) {
                                return "Please enter your username";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          /// Password field
                          TextFormField(
                            controller: _passController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              labelText: "Password",
                              hintText: "Enter your password",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  onPressed: () {
                                    setState(
                                        () => _obscurePass = !_obscurePass);
                                  }),
                            ),
                            obscureText: _obscurePass,
                            validator: (pass) {
                              if (pass?.isEmpty ?? true) {
                                return "Please enter your password";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          /// Sign In button
                          SizedBox(
                            width: double.maxFinite,
                            child: DefaultButton(
                              child: const Text("Sign In",
                                  style: TextStyle(fontSize: 18)),
                              onPressed: () {
                                /// Validate form
                                if (_formKey.currentState!.validate()) {
                                  String email =
                                      _usernameController.text.trim();
                                  String password = _passController.text.trim();
                                  // Admin sign in
                                  AuthService()
                                      .loginWithEmailPassword(email, password)
                                      .then(
                                    (User? value) {
                                      if (value != null) {
                                        Future(() {
                                          Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Dashboard()));
                                        });
                                      }
                                    },
                                  );
                                  AppModel().adminSignIn(
                                      username: _usernameController.text.trim(),
                                      password: _passController.text.trim(),
                                      onSuccess: () {
                                        /// Go to dashboard
                                        Future(() {
                                          Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Dashboard()));
                                        });
                                      },
                                      onError: () {
                                        // Show error message
                                        showScaffoldMessage(
                                            context: context,
                                            scaffoldkey: _scaffoldKey,
                                            bgcolor: Colors.black,
                                            message:
                                                "Username or Password is invalid.\nPlease try again!");
                                      });
                                }
                              },
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
        ),
      ),
    );
  }
}
