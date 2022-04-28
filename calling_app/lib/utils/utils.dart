import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future setNullInFirebaseDataField() async {
  final user = FirebaseAuth.instance.currentUser!;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({'data': jsonEncode(null)}, SetOptions(merge: true)); // merge means other field remain same just change this data field
}

const snackBar = SnackBar(
  content: Text('Invite sent to the user.'),
);

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

Future<int> getUserId() async {
  int userId = 0;
  SharedPreferences preferences = await SharedPreferences.getInstance();
  int? storedUID = preferences.getInt("localUID");
  if (storedUID != null) {
    userId = storedUID;
    print("Settled UserId: $userId");
  } else {
    int time = DateTime.now().millisecondsSinceEpoch;
    userId =
        int.parse(time.toString().substring(1, time.toString().length - 3));
    preferences.setInt("localUID", userId);
    print("Settled UserId: $userId");
  }

  return userId;
}
