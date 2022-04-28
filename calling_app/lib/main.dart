import 'dart:convert';

import 'package:calling_app/controllers/director_controller.dart';
import 'package:calling_app/controllers/static_handler.dart';
import 'package:calling_app/pages/HomePage.dart';
import 'package:calling_app/utils/utils.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';



Future<void> makeFakeCallInComing(Map<String, dynamic> data,
    {bool fromBackground = false}) async {
  await Future.delayed(const Duration(microseconds: 1), () async {
    data["fromBackground"] = fromBackground; // adding background variable

    var params = <String, dynamic>{
      'id': data["activeUsers"][0],
      'nameCaller': data["name"],
      'appName': 'Family Call',
      'avatar': '/android/src/main/res/drawable-xxxhdpi/ic_default_avatar.png',
      'handle': data["email"],
      'type': 1,
      // 0 for call 1 for video
      'duration': 30000,
      // This is the total ringing time
      'extra': data,
      // An Extra Data for event
      // The given data is for designing no need to touch
      'android': <String, dynamic>{
        'isCustomNotification': true,
        'isShowLogo': false,
        'ringtonePath': 'ringtone_default',
        'backgroundColor': '#0955fa',
        'background':
            '/android/src/main/res/drawable-xxxhdpi/ic_default_avatar.png',
        'actionColor': '#4CAF50'
      },
      'ios': <String, dynamic>{
        'iconName': 'AppIcon40x40',
        'handleType': '',
        'supportsVideo': true,
        'maximumCallGroups': 2,
        'maximumCallsPerCallGroup': 1,
        'audioSessionMode': 'default',
        'audioSessionActive': true,
        'audioSessionPreferredSampleRate': 44100.0,
        'audioSessionPreferredIOBufferDuration': 0.005,
        'supportsDTMF': true,
        'supportsHolding': true,
        'supportsGrouping': false,
        'supportsUngrouping': false,
        'ringtonePath': 'Ringtone.caf'
      }
    };
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  });
}

// Platform messages are asynchronous, so we initialize in an async method.
Future<void> listenerEvent() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  // We also handle the message potentially returning null.
  try {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      print("event triggered");
      print(event?.name); // for event name
      print(event?.body); // for event body

      switch (event!.name) {
        case CallEvent.ACTION_CALL_INCOMING:
          // TODO: received an incoming call
          break;
        case CallEvent.ACTION_CALL_START:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
          break;
        case CallEvent.ACTION_CALL_ACCEPT:
          // This will contain data which we sent
          Map<String, dynamic> body = event.body;
          // TODO: accepted an incoming call
          // TODO: show screen calling in Flutter

          if (!body["extra"]["fromBackground"]) {
            DirectorController d = SH.dc;
            d.pushScreenFromNotification(body["extra"]);
          } else {


            // try {
            //   // For mocking the initial values because we are in the background otherwise it will throw error
            //   // SharedPreferences.setMockInitialValues({});
            //   // SharedPreferences preferences = await SharedPreferences.getInstance();
            //
            //   body["extra"]["time"] = DateTime.now().toString(); // setting current time
            //   print("inside else");
            //   print(body["extra"]);
            //   // preferences.setString("callData", jsonEncode(body["extra"]));
            // } catch(e) {
            //   print("in error $e");
            // }

          }

          break;
        case CallEvent.ACTION_CALL_DECLINE:
          // TODO: declined an incoming call
          print("after clear");
          break;
        case CallEvent.ACTION_CALL_ENDED:
          // TODO: ended an incoming/outgoing call
          break;
        case CallEvent.ACTION_CALL_TIMEOUT:
          // TODO: missed an incoming call
          break;
        case CallEvent.ACTION_CALL_CALLBACK:
          // TODO: only Android - click action `Call back` from missed call notification
          break;
        case CallEvent.ACTION_CALL_TOGGLE_HOLD:
          // TODO: only iOS
          break;
        case CallEvent.ACTION_CALL_TOGGLE_MUTE:
          // TODO: only iOS
          break;
        case CallEvent.ACTION_CALL_TOGGLE_DMTF:
          // TODO: only iOS
          break;
        case CallEvent.ACTION_CALL_TOGGLE_GROUP:
          // TODO: only iOS
          break;
        case CallEvent.ACTION_CALL_TOGGLE_AUDIO_SESSION:
          // TODO: only iOS
          break;
      }
    });
  } on Exception {}
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  await Firebase.initializeApp();

  listenerEvent(); // Registering event calls


  try {

    // Here setup time checker if the data is too old from current time then not make the call here
    // get notification send time from message.data['time'];
    DateTime dt = DateTime.parse(
        message.data['time']); // parsing the string to date time format
    dt = dt.add(const Duration(seconds: 7)); // adding 7 second to the date


    // // checking if the notification date is after current time date then show notification other wise no need to show
    if (dt.isAfter(DateTime.now())) {
      makeFakeCallInComing(message.data, fromBackground: true);
      await ClearAllNotifications.clear(); // For Clearing notification tray
    } else {
      await setNullInFirebaseDataField();
    }
  } catch (e) {
    print("big error " + e.toString());
  }

  print('Handling a background message ${message.messageId}');
  // print(message.notification.title);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var textEvents = "";
  bool show = false;



  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => show = true);
    });

    listenerEvent(); // Registering event calls

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      print("Initial Msg ${message?.data.toString()}");
    });

    // While app is running this will handle the message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (SH.dc.inConnection.value == false) {
        await ClearAllNotifications.clear(); // For Clearing notification tray
        makeFakeCallInComing(message.data);
      } else {
        print("he is in connection already");
      }

      print("Here is the message in onMessage ${message.data}");
      print("value of isConntion");
      print(SH.dc.inConnection.value);
    });

    // When we open the app by clicking the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Here is the message in onMessageAppOpened ${message.data}");
    });
  }

  Future<void> signInGoogle() async {
    try {
      GoogleSignInAccount? _account = await googleSignIn.signIn();
      if (_account == null) return;

      print("After sign in");
      final googleAuth = await _account.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // generate fcm token
      final token = await FirebaseMessaging.instance.getToken();

      // If the user exists with that id then it will update otherwise it will add the new user
      await FirebaseFirestore.instance
          .collection('users') // getting user collection
          .doc(authResult.user?.uid) // getting document with userid
          .set({
        // setting the data
        'email': authResult.user?.email,
        'name': authResult.user?.displayName,
        'photo': authResult.user?.photoURL,
        'fcm': token,
        'createdAt': DateTime.now(),
        'data': jsonEncode(null)
      });
    } catch (err) {
      print("Error $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    return !show
        ? Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/icon.png"),
                const CircularProgressIndicator()
              ],
            ),
          )
        : GetMaterialApp(
            home: Scaffold(
              body: StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasData) {
                    // You will get the current logged in user
                    return const HomePage();
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Something Went Wrong!"));
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              await signInGoogle();
                            },
                            child: Image.asset(
                              "assets/googleImg.png",
                              width: 200,
                              height: 200,
                            ),
                          ),
                          const Text(
                            "Login With Google",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          );
  }
}
