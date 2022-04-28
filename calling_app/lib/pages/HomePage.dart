import 'dart:convert';
import 'dart:core';

import 'package:calling_app/controllers/director_controller.dart';
import 'package:calling_app/controllers/static_handler.dart';
import 'package:calling_app/pages/Director.dart';
import 'package:calling_app/utils/utils.dart';
import 'package:calling_app/utils/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final bool isFromDirector;
  final String channelName;
  final List<int> userIds;

  const HomePage({Key? key, this.isFromDirector = false, this.channelName = "", this.userIds = const [] }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController searchText = TextEditingController(text: "");
  bool showSearch = false;
  List<QueryDocumentSnapshot<Object?>>? docsData = [];

  Future<void> logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }

  Future<void> checkCall() async {
    final data = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final notifyData = jsonDecode(data.get("data"));
    if (notifyData != null) {
      DirectorController d = SH.dc;
      d.pushScreenFromNotification(notifyData["data"], fromHomePage: true);
    }
  }

  @override
  void initState() {
    // here we will use it for getting the data on resume will call
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('SystemChannels> $msg');

      if (msg == AppLifecycleState.resumed.toString()) {
        // here we will getting the data from the field
        await checkCall();
      }
      return await Future.value();
    });

    Future.delayed(const Duration(microseconds: 1), () async {
      // checking data and then reacting accordingly
      await checkCall();
      // Getting Premissions
      await [Permission.camera, Permission.microphone].request();
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: widget.isFromDirector
          ? PreferredSize(
              child: customSearchField(
                  controller: searchText,
                  size: size,
                  onChange: (e) {
                    setState(() {});
                  }),
              preferredSize: Size(size.width, 70))
          : AppBar(
              leading: null,
              title: const Text("Family Call"),
              centerTitle: true,
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() => showSearch = !showSearch);
                    },
                    icon: const Icon(Icons.search))
              ],
              bottom: !showSearch
                  ? null
                  : PreferredSize(
                      child: customSearchField(
                          controller: searchText,
                          size: size,
                          onChange: (e) {
                            setState(() {});
                          }),
                      preferredSize: Size(size.width, 70)),
            ),
      body: StreamBuilder(
        // so we .orderBy('createdAt', descending: true) order according to the time stamp in decending order because we want to show the data in chat form
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasData) {
            if (searchText.text.trim() == "") {
              docsData = snapshot.data?.docs;
            } else {
              List<QueryDocumentSnapshot<Object?>>? tempData = [];
              snapshot.data?.docs.forEach((doc) {
                if (doc['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchText.text.toLowerCase())) {
                  tempData.add(doc);
                }
              });
              docsData = tempData;
            }

            // If the user exist with that email it will return otherwise it will throw error
            // FirebaseFirestore.instance.collection('users').where('email', isEqualTo: 'khannasahil303@gmail.com').get().then((value) {
            //   print("value is ${value.docs[0]['name']}");
            // });

            // print("Here is the data ${docsData?[0]['email']}");
            // key: ValueKey(docsData[index].documentId)
            return ListView.builder(
              // reverse: true, // it will scroll from bottom to the top
              itemBuilder: (ctx, index) =>
                  (docsData?[index]['email'] == user.email)
                      ? Container()
                      : InkWell(
                          onTap: () async {
                            if (widget.isFromDirector) {
                              // Here we will sending the push notification call to the one more user
                              await SH.dc.sendPushMessage(
                                channelName: widget.channelName,
                                fcmToken: docsData?[index]['fcm'] ?? "",
                                name: user.displayName.toString(),
                                email: user.email.toString(),
                                toWhomSendId: docsData?[index].id ?? "",
                                activeUsers: widget.userIds,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            } else {
                              Get.to(
                                () => Director(
                                  isDirector: true,
                                  fcmToken: docsData?[index]['fcm'],
                                  toWhomSendId: docsData?[index].id ?? "",
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5)),
                            margin: const EdgeInsets.all(5),
                            child: Material(
                              elevation: 10.0,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(docsData?[index]['photo']),
                                ),

                                // tileColor: Colors.redAccent,
                                title: Text(docsData?[index]['name']),
                                subtitle: Text(docsData?[index]['email']),
                                trailing: widget.isFromDirector
                                    ? null
                                    : const Icon(Icons.videocam),

                              ),
                            ),
                          ),
                        ),
              itemCount: docsData?.length,
            );
          } else {
            return const Center(child: Text("Something Went Wrong!"));
          }
        },
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName.toString()),
              accountEmail: Text(user.email.toString()),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL.toString()),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ListTile(
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  tileColor: Colors.blue,
                  title: const Text("Logout",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: logout,
                  trailing: const Icon(Icons.logout),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
