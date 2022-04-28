import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:calling_app/models/user.dart';

class DirectorModel {
  RtcEngine? engine; // video call
  Set<AgoraUser> allUsers;
  AgoraUser? localUser;
  String? channelName;

  DirectorModel({
    this.engine,
    this.allUsers = const {},
    this.localUser,
    this.channelName
  });

  DirectorModel copyWith({
    RtcEngine? engine,
    Set<AgoraUser>? allUsers,
    AgoraUser? localUser,
    String? channelName,
  }) {
    return DirectorModel(
      engine: engine ?? this.engine,
      allUsers: allUsers ?? this.allUsers,
      localUser: localUser ?? this.localUser,
      channelName: channelName,
    );
  }
}
