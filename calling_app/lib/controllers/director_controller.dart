import 'dart:convert';

import 'package:calling_app/pages/Director.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:calling_app/controllers/director_model.dart';
import 'package:calling_app/models/user.dart';
import 'package:calling_app/utils/app_id.dart';
import 'package:calling_app/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DirectorController extends GetxController {
  String uniqueId = 'DirectorController';
  RxBool inConnection = false.obs;
  final d = DirectorModel().obs;

  void updateData() {

    print("Updating data");
    update([uniqueId]);
  }

  Future<void> initialize(String channelName, {Set<AgoraUser> allUsers = const {}}) async {
    RtcEngine engine =
        await RtcEngine.createWithContext(RtcEngineContext(appId));

    final user = FirebaseAuth.instance.currentUser!;

    AgoraUser localUser = AgoraUser(
        userId: await getUserId(),
        muted: false,
        videoDisabled: false,
        name: user.displayName);
    d.value = DirectorModel(engine: engine, localUser: localUser, channelName: channelName, allUsers: allUsers);
  }

  Future<void> joinCall({
    required String channelName,
    required int userId,
    required String token,
    required bool isDirector
  }) async {

    if(isDirector) await initialize(channelName);

    // Enabling some profiles
    await d.value.engine?.enableVideo();
    await d.value.engine?.enableAudio();
    await d.value.engine?.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await d.value.engine?.setClientRole(ClientRole.Broadcaster);

    print("here is the data");
    print(token + " " + channelName + " " + userId.toString());
    await d.value.engine
        ?.joinChannel(token, channelName, "Optional Info", userId);

    // Callbacks for the RTC Engine
    // setting event handler
    d.value.engine?.setEventHandler(RtcEngineEventHandler(
      error: (er) {
        print("Here is the error $er");
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        // TODO: Add Handler Logic
        print("Director $userId");
      },
      leaveChannel: (stats) {},
      userJoined: (uid, elapsed) {
        print("Here we joined $uid");
        // When a user Joined here
        addUser(userId: uid);
      },
      userOffline: (uid, reason) {
        print("Offline"); // When user end the call
        removeUser(userId: uid);
      },
      // When someone changes it audio state
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        if (state == AudioRemoteState.Decoding) {
          updateUserAudio(userId: uid, muted: false);
        } else if (state == AudioRemoteState.Stopped) {
          updateUserAudio(userId: uid, muted: true);
        }
      },
      // When someone changes it's video state
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        if (state == VideoRemoteState.Decoding) {
          updateUserVideo(userId: uid, videoDisabled: false);
        } else if (state == VideoRemoteState.Stopped) {
          updateUserVideo(userId: uid, videoDisabled: true);
        }
      },
    ));

    // Callbacks for RTM Channel
    updateData();
  }

  Future<void> leaveCall() async {
    try{
      d.value.engine?.leaveChannel();
      d.value.engine?.destroy();
      d.value.channelName = null;
      d.value.allUsers.clear();
      // updateData();
    } catch(e) {}
  }

  Future<void> addUser({required int userId}) async {
    // Spreading all the user we have in set and adding new user

    d.value = d.value.copyWith(allUsers: {
      ...d.value.allUsers,
      AgoraUser(
        userId: userId,
        muted: false,
        videoDisabled: false,
        name: "Name",
        backgroundColor: Colors.blue,
      )
    });

    updateData();
  }

  // This function is called from Engine Event Handler
  Future<void> removeUser({required int userId}) async {
    Set<AgoraUser> _allUsers = d.value.allUsers;

    for (int i = 0; i < _allUsers.length; i++) {
      if (_allUsers.elementAt(i).userId == userId) {
        _allUsers.remove(_allUsers.elementAt(i));
      }
    }

    d.value = d.value.copyWith(
      allUsers: _allUsers,
    );

    updateData();
  }

  Future<void> updateUserAudio(
      {required int userId, required bool muted}) async {
    try {
      AgoraUser _tempUser =
          d.value.allUsers.singleWhere((element) => element.userId == userId);
      Set<AgoraUser> _tempSet = d.value.allUsers;
      _tempSet.remove(_tempUser);
      _tempSet.add(_tempUser.copyWith(muted: muted));
      d.value = d.value.copyWith(allUsers: _tempSet);
      updateData();
    } catch (e) {}
  }

  Future<void> updateUserVideo(
      {required int userId, required bool videoDisabled}) async {
    try {
      AgoraUser _tempUser =
          d.value.allUsers.singleWhere((element) => element.userId == userId);
      Set<AgoraUser> _tempSet = d.value.allUsers;
      _tempSet.remove(_tempUser);
      _tempSet.add(_tempUser.copyWith(videoDisabled: videoDisabled));
      d.value = d.value.copyWith(allUsers: _tempSet);

      updateData();
    } catch (e) {}
  }

  Future<void> pushScreenFromNotification(body, {bool fromHomePage = false}) async {

    if(inConnection.value == false) {

      try {
        print("in try catch");
        Set<AgoraUser> tempUsers = {};

        List ids = fromHomePage ? body["activeUsers"] : jsonDecode(body["activeUsers"]);
        for (int i = 0; i < ids.length; i++) {
          tempUsers.add(AgoraUser(
            userId: ids.elementAt(i),
            muted: false,
            videoDisabled: false,
            name: "Name",
            backgroundColor: Colors.blue,
          ));
        }

        // So automatically when we joined the existed user id is added if not added then use this way to add the ids
        initialize(body["channelName"]);

        await setNullInFirebaseDataField(); // setting firebase data field to null because we used the data
        Get.to(() => const Director(fcmToken: "", isDirector: false));

      } catch (err) {
        print("Error is $err");
      }

    } else {
      print("Already in the connection");
    }

  }

  Future<List<int>> getAllUsersId() async {
    try {
      Set<AgoraUser> users = d.value.allUsers;
      List<int> activeUsers = [];

      // Adding all users id's who are in call now
      for(int i = 0; i< users.length; i++) {
        activeUsers.add(users.elementAt(i).userId);
      }
      activeUsers.add(await getUserId());
      return activeUsers;
    } catch(e) {
      print("Error is $e");
    }

    return [await getUserId()];

  }

  Future<void> sendPushMessage({
    required String fcmToken,
    required String name,
    required String email,
    required String toWhomSendId,
    required String channelName,
    required List<int> activeUsers,
  }) async {
    try {
      final body = jsonEncode({
        "to": fcmToken,
        "data": {"name": name, "email": email, "activeUsers": activeUsers, "channelName": channelName, "toWhomSendId": toWhomSendId, "time": DateTime.now().toString()},
        "notification": {
          "title": "Calling To $name",
          "body": "Pick Up the Call $name"
        }
      });

      // saving data to the user data field to whom we sending call notification
      await FirebaseFirestore.instance
          .collection('users') // getting user collection
          .doc(toWhomSendId) // getting document with userid
          .set({'data': body}, SetOptions(merge: true));  // merge means other field remain same just change this data field

      // Here we sending notification to the user
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$fcmServerKey'
        },
        body: body,
      );
      print('FCM request for device sent!');
    } catch (e) {
      print("Error while sending request $e");
    }
  }

  Future<String> generateAgoraToken(String channelName) async {
    try {
      // So this server we made ourself to generate agora token
      // http://go-agora-server.herokuapp.com/fetch_rtc_token

      //  0 => roleAttendee
      // 1 => rolePublisher
      // 2 => roleSubscriber
      // 101 => roleAdmin

      final res = await http.post(
        Uri.parse('http://go-agora-server.herokuapp.com/fetch_rtc_token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$fcmServerKey'
        },
        body: jsonEncode({
          "uid": await getUserId(),
          "channelName": channelName,
          "role": 101
        }),
      );

      final body = jsonDecode(res.body);
      return body["token"];
    } catch (err) {
      rethrow;
    }
  }
}
