class RoomModel {
  final String id;
  final String name;
  final UserBasic creator;
  final List<UserBasic> members;
  final MessageModel? lastMessage;
  final String? reservationId;
  final String? roomType; // 'general' or 'reservation'
  final String? agentCommercialId; // For reservation rooms
  final String? agentTerrainId; // For reservation rooms
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.creator,
    required this.members,
    this.lastMessage,
    this.reservationId,
    this.roomType,
    this.agentCommercialId,
    this.agentTerrainId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      creator: UserBasic.fromJson(json['creator'] ?? {}),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((m) => UserBasic.fromJson(m))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      reservationId: json['reservationId'],
      roomType: json['roomType'],
      agentCommercialId: json['agentCommercialId'],
      agentTerrainId: json['agentTerrainId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'creator': creator.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    UserBasic? creator,
    List<UserBasic>? members,
    MessageModel? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      creator: creator ?? this.creator,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserBasic {
  final String id;
  final String name;
  final String email;
  final String role;
  final ProfilePhoto? profilePhoto;

  UserBasic({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePhoto,
  });

  factory UserBasic.fromJson(Map<String, dynamic> json) {
    return UserBasic(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      profilePhoto: json['profilePhoto'] != null
          ? ProfilePhoto.fromJson(json['profilePhoto'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'profilePhoto': profilePhoto?.toJson(),
    };
  }
}

class ProfilePhoto {
  final String? url;
  final String? publicId;

  ProfilePhoto({this.url, this.publicId});

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(url: json['url'], publicId: json['publicId']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'publicId': publicId};
  }
}

class MessageModel {
  final String id;
  final String roomId;
  final UserBasic sender;
  final String type; // 'text' or 'voice'
  final String text;
  final String? voiceUrl;
  final int? voiceDuration;
  final List<String> seenBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.sender,
    required this.type,
    required this.text,
    this.voiceUrl,
    this.voiceDuration,
    required this.seenBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['room'] is String
          ? json['room']
          : (json['room']?['_id'] ?? json['room']?['id'] ?? ''),
      sender: UserBasic.fromJson(json['sender'] ?? {}),
      type: json['type'] ?? 'text',
      text: json['text'] ?? '',
      voiceUrl: json['voiceUrl'],
      voiceDuration: json['voiceDuration'],
      seenBy:
          (json['seenBy'] as List<dynamic>?)
              ?.map((id) => id is String ? id : id.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'room': roomId,
      'sender': sender.toJson(),
      'type': type,
      'text': text,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'seenBy': seenBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? roomId,
    UserBasic? sender,
    String? type,
    String? text,
    String? voiceUrl,
    int? voiceDuration,
    List<String>? seenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      text: text ?? this.text,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      seenBy: seenBy ?? this.seenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isSeenBy(String userId) {
    return seenBy.contains(userId);
  }

  bool get isVoice => type == 'voice';
  bool get isText => type == 'text';
  bool get isRapport => type == 'rapport';
}
