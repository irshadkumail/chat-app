import 'package:chat_appv2/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatelessWidget {
  final String userID;

  ChatScreen({@required this.userID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        backgroundColor: Colors.white,
        leading: IconButton(
            icon: Icon(Icons.keyboard_return),
            onPressed: () => FirebaseAuth.instance.signOut()),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection(FirebaseConstants.MESSAGE_COLLECTION)
                  .orderBy(FirebaseConstants.DOCUMENT_CREATED_FIELD)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  final documentSnapshot = snapshot.data.documents;
                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (ctx, pos) => MessageDisplayWidget(
                          messageText: documentSnapshot[pos]
                              .data[FirebaseConstants.DOCUMENT_TEXT_FIELD],
                          isMe: documentSnapshot[pos]
                                  .data[FirebaseConstants.DOCUMENT_UID_FIELD] ==
                              userID),
                      itemCount: documentSnapshot.length,
                    ),
                  );
                }
              }),
          MessageInputWidget(userID: userID)
        ],
      ),
    );
  }
}

class MessageDisplayWidget extends StatelessWidget {
  final String messageText;

  final bool isMe;

  MessageDisplayWidget({@required this.messageText, @required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              if (!isMe)
                CircleAvatar(backgroundColor: Colors.grey, radius: 15,),
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 60),
                  padding: EdgeInsets.all(16),
                  margin: isMe ?  EdgeInsets.all(0) : EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                      color: isMe ? Colors.grey : Theme.of(context).primaryColor,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomLeft: isMe ? Radius.circular(10) : Radius.circular(0),
                          bottomRight:
                              isMe ? Radius.circular(0) : Radius.circular(10))),
                  child: Text(messageText))
            ],
          ),
        ],
      ),
    );
  }
}

class MessageInputWidget extends StatefulWidget {
  final String userID;

  MessageInputWidget({@required this.userID});

  @override
  _MessageInputWidgetState createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final _messageController = TextEditingController();

  void _onSendPressed() async {
    if (_messageController.text != null) {
      FocusScope.of(context).requestFocus(new FocusNode());
      await Firestore.instance
          .collection(FirebaseConstants.MESSAGE_COLLECTION)
          .document()
          .setData({
        FirebaseConstants.DOCUMENT_TEXT_FIELD: _messageController.text,
        FirebaseConstants.DOCUMENT_UID_FIELD: widget.userID,
        FirebaseConstants.DOCUMENT_CREATED_FIELD:
            DateTime.now().toIso8601String()
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
              child: TextField(
            controller: _messageController,
            style: TextStyle(color: Colors.grey),
            decoration: InputDecoration(
              labelText: "Type message here",
              focusColor: Colors.grey,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSendPressed(),
          )),
          Container(
              height: 60.0,
              width: 60.0,
              padding: EdgeInsets.all(4),
              child: FloatingActionButton(
                onPressed: _onSendPressed,
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ))
        ],
      ),
    );
  }
}
