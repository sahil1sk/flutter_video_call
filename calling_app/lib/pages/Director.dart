import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:calling_app/controllers/director_controller.dart';
import 'package:calling_app/controllers/static_handler.dart';
import 'package:calling_app/pages/HomePage.dart';
import 'package:calling_app/utils/app_id.dart';
import 'package:calling_app/utils/utils.dart';
import 'package:calling_app/utils/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Director extends StatefulWidget {
  final String fcmToken;
  final bool isDirector;
  final String toWhomSendId;

  const Director({
    Key? key,
    required this.fcmToken,
    this.isDirector = false,
    this.toWhomSendId = "",
  }) : super(key: key);

  @override
  _DirectorState createState() => _DirectorState();
}

class _DirectorState extends State<Director> {
  DirectorController d = SH.dc;
  var uuid = Uuid();
  bool showLoading = false;
  int userId = 0;
  bool showConnection = true;
  String channelName = "";

  @override
  void initState() {
    super.initState();

    // setting we are in connection
    d.inConnection.value = true;

    if (widget.isDirector) {
      // If user not responded then pop will happen because of our BroadCast view container
      Future.delayed(const Duration(seconds: 30), () async {
        setState(() => showConnection = false);
      });
    }

    Future.delayed(const Duration(microseconds: 1), () async {
      userId = await getUserId();
      if (widget.isDirector) {
        // Put token generation code here using channel
        if (d.d.value.channelName == null) {
          channelName = uuid.v1();
          d.d.value.channelName = channelName;
        }



        final user = FirebaseAuth.instance.currentUser!;
        await d.sendPushMessage(
          channelName: d.d.value.channelName.toString(),
          fcmToken: widget.fcmToken,
          name: user.displayName.toString(),
          email: user.email.toString(),
          toWhomSendId: widget.toWhomSendId,
          activeUsers: await d.getAllUsersId(),
        );
      }

      // d.d.value.channelName.toString() (So in this value is settled automatically if it is not called by director by this => pushScreenFromNotification function)

      channelName = d.d.value.channelName.toString();
      await d.joinCall(
          channelName: channelName,
          userId: await getUserId(),
          token: await d.generateAgoraToken(channelName),
          isDirector: widget.isDirector);

      await Future.delayed(const Duration(seconds: 1));
      setState(() => showLoading = true);
    });
  }

  Future<void> sendInvite() async {
    Size size = MediaQuery.of(context).size;
    List<int> ids = await d.getAllUsersId();

    print("here is the data");
    print(ids);
    print(channelName);
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: SizedBox(
              height: size.height - 200,
              width: size.width,
              child: HomePage(isFromDirector: true, channelName: channelName, userIds: ids),
            ),
            actions: const <Widget>[],
          );
        });
  }

  @override
  void dispose() {
    // setting we are not in connection
    d.inConnection.value = false;
    d.leaveCall();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GetBuilder<DirectorController>(
          id: d.uniqueId,
          init: d,
          builder: (controller) {

            return Scaffold(
              body: !showLoading
                  ? (const SizedBox(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ))
                  : Center(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                            0, MediaQuery.of(context).padding.top, 0, 0),
                        child: Stack(
                          children: [
                            _broadCastView(),
                            _toolBar(),
                            _ourView(),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: customButtons(
                                function: sendInvite,
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.blueAccent,
                                  size: 20.0,
                                ),
                                color: Colors.white,
                                padding: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          }),
    );
  }

  Widget _toolBar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        children: <Widget>[
          customButtons(
            function: onToggleMute,
            icon: Icon(
              d.d.value.localUser!.muted ? Icons.mic_off : Icons.mic,
              color:
                  d.d.value.localUser!.muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            color: d.d.value.localUser!.muted ? Colors.blueAccent : Colors.white,
            padding: 12.0,
          ),
          customButtons(
            function: onCallEnd,
            icon: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            color: Colors.redAccent,
            padding: 15.0,
          ),
          customButtons(
            function: onToggledVideoDisabled,
            icon: Icon(
              d.d.value.localUser!.videoDisabled
                  ? Icons.videocam_off
                  : Icons.videocam,
              color: d.d.value.localUser!.videoDisabled
                  ? Colors.white
                  : Colors.blueAccent,
              size: 20.0,
            ),
            color: d.d.value.localUser!.videoDisabled
                ? Colors.blueAccent
                : Colors.white,
            padding: 12.0,
          ),
          customButtons(
            function: onSwitchCamera,
            icon: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            color: Colors.white,
            padding: 12.0,
          ),
        ],
      ),
    );
  }

  Widget _ourView() {
    return Positioned(
      top: 0,
      right: 0,
      height: 120,
      width: 120,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: rtc_local_view.SurfaceView()),
    );
  }

  Widget _broadCastView() {
    if (d.d.value.allUsers.isEmpty && showConnection) {
      return Center(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [CircularProgressIndicator(), Text("Ringing....")]),
      );
    } else if (d.d.value.allUsers.isEmpty && !showConnection) {
      return Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
            Text(
              "User Not Respondive",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "Connection declined...",
              style: TextStyle(fontSize: 17),
            )
          ]));
    }

    // Getting first user and connecting it

    showConnection = false;
    final users = d.d.value.allUsers;
    if (users.length == 1) {
      return SizedBox(
        height: (MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top),
        width: MediaQuery.of(context).size.width,
        child: rtc_remote_view.SurfaceView(uid: users.elementAt(0).userId),
      );
    } else if (users.length == 2) {
      return SizedBox(
        height: (MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top),
        width: MediaQuery.of(context).size.width,
        child: Column(children: [
          Expanded(
              child: rtc_remote_view.SurfaceView(
                  uid: users.elementAt(0).userId)),
          Expanded(
              child: rtc_remote_view.SurfaceView(
                  uid: users.elementAt(1).userId)),
        ]),
      );
    }

    return Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text("No Connection..."), Text("No Response...")]),
    );
  }

  // Muting and unmuting
  void onToggleMute() {
    setState(() {
      d.d.value.localUser!.muted = !d.d.value.localUser!.muted;
    });

    d.d.value.engine!.muteLocalAudioStream(d.d.value.localUser!.muted);
  }

  // video disabling and enabling
  void onToggledVideoDisabled() {
    setState(() {
      d.d.value.localUser!.videoDisabled = !d.d.value.localUser!.videoDisabled;
    });
    d.d.value.engine!.muteLocalVideoStream(d.d.value.localUser!.videoDisabled);
  }

  void onSwitchCamera() => d.d.value.engine!.switchCamera();

  void onCallEnd() => Navigator.pop(
      context); // Just Popping the screen the end call method will handled in dispose method

}
