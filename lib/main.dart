import 'package:flutter/material.dart';
import 'screen/sign_up_screen.dart';
import 'screen/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: StreamBuilder<FirebaseUser>(
          stream: FirebaseAuth.instance.onAuthStateChanged,
          builder: (context, snapshot) {
            return snapshot.data != null
                ? ChatScreen(userID: snapshot.data.uid)
                : SignUpScreen();
          }),
    );
  }
}
