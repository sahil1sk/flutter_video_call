import 'package:flutter/cupertino.dart';

class AgoraUser {
  int userId;
  bool muted;
  bool videoDisabled;
  String? name;
  Color? backgroundColor;

  AgoraUser({
    required this.userId,
    this.muted = false,
    this.videoDisabled = false,
    this.name,
    this.backgroundColor,
  });

  AgoraUser copyWith({
    int? userId,
    bool? muted,
    bool? videoDisabled,
    String? name,
    Color? backgroundColor,
  }) {
    return AgoraUser(
      userId: userId ?? this.userId,
      muted: muted ?? this.muted,
      videoDisabled: videoDisabled ?? this.videoDisabled,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
