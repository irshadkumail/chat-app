import 'dart:io';

import 'package:chat_appv2/screen/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_appv2/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum ScreenState { LOGIN, SIGN_UP }

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;

  ScreenState _currentScreenState = ScreenState.LOGIN;
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String _fullName;
  String _email;
  String _password;
  String _profileImage = "";
  bool isLoading = false;

  void _goToChatScreen(String userId) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ChatScreen(userID: userId)));
  }

  Future<void> _saveForm() async {
    try {
      if (_currentScreenState == ScreenState.SIGN_UP && _profileImage.isEmpty) {
        Scaffold.of(_formKey.currentState.context).showSnackBar(
            SnackBar(content: Text("Please select profile image")));
      }

      if (!_formKey.currentState.validate()) {
        return;
      }
      _formKey.currentState.save();
      if (_currentScreenState == ScreenState.LOGIN) {
        var authResult = await _auth.signInWithEmailAndPassword(
            email: _email, password: _password);
        _goToChatScreen(authResult.user.uid);
      } else {
        var authResult = await _auth.createUserWithEmailAndPassword(
            email: _email, password: _password);
        final reference =
            FirebaseStorage.instance.ref().child(authResult.user.uid + ".jpg");
        await reference.putFile(File(_profileImage)).onComplete;
        final url = await reference.getDownloadURL();
        await Firestore.instance
            .collection(FirebaseConstants.USERS_COLLECTION)
            .document(authResult.user.uid)
            .setData({
          FirebaseConstants.DOCUMENT_NAME: _fullName,
          FirebaseConstants.DOCUMENT_PIC_FIELD: url
        });
        _goToChatScreen(authResult.user.uid);
      }
    } on PlatformException catch (error) {
      Scaffold.of(_formKey.currentState.context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      Scaffold.of(_formKey.currentState.context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _checkForEmpty(String value, String label) {
    if (value.isEmpty) {
      return "$label cannot be empty";
    } else {
      return null;
    }
  }

  void _changeState() {
    if (ScreenState.LOGIN == _currentScreenState) {
      _currentScreenState = ScreenState.SIGN_UP;
    } else {
      _currentScreenState = ScreenState.LOGIN;
    }
  }

  void _pickImage() async {
    final pickedImage = await ImagePicker()
        .getImage(source: ImageSource.camera, imageQuality: 40);
    if (pickedImage != null)
      setState(() {
        _profileImage = pickedImage.path;
      });
  }

  Widget _buildInputField() {
    return Column(
      children: <Widget>[
        if (ScreenState.SIGN_UP == _currentScreenState)
          CircleAvatar(
            radius: 40,
            backgroundImage: FileImage(File(_profileImage)),
            child: IconButton(
                icon: Icon(Icons.camera_enhance), onPressed: _pickImage),
          ),
        if (ScreenState.SIGN_UP == _currentScreenState) SizedBox(height: 10),
        if (ScreenState.SIGN_UP == _currentScreenState)
          TextFormField(
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
                labelText: "Full name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            validator: (input) => _checkForEmpty(input, "Full name"),
            onSaved: (input) => _fullName = input,
          ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          onSaved: (input) => _email = input,
          validator: (input) => _checkForEmpty(input, "Email"),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocusNode,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: InputDecoration(
              labelText: "Email",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          onSaved: (input) => _password = input,
          validator: (input) => _checkForEmpty(input, "Password"),
          focusNode: _passwordFocusNode,
          keyboardType: TextInputType.visiblePassword,
          maxLength: 8,
          obscureText: true,
          decoration: InputDecoration(
              labelText: "Password",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    ScreenState.LOGIN == _currentScreenState
                        ? "Welcome,"
                        : "Create Account,",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 31, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    ScreenState.LOGIN == _currentScreenState
                        ? "Sign In to continue"
                        : "Sign Up to get Started",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                (ScreenState.SIGN_UP == _currentScreenState)
                    ? SizedBox(height: 20)
                    : SizedBox(height: 80),
                _buildInputField(),
                SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 48,
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RaisedButton(
                          onPressed: () => _saveForm(),
                          child: Text(
                            ScreenState.LOGIN == _currentScreenState
                                ? "Login"
                                : "Sign Up",
                            style: TextStyle(color: Colors.white),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          color: Theme.of(context).primaryColor,
                        ),
                ),
                Spacer(),
                Center(
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        _changeState();
                      });
                    },
                    child: RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: ScreenState.LOGIN == _currentScreenState
                              ? "No account yet? "
                              : "I'm already a member",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      TextSpan(
                          text: ScreenState.LOGIN == _currentScreenState
                              ? "Sign Up"
                              : "Log In",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor))
                    ])),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
