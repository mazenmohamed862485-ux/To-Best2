class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String? program;
  final int? programDays;
  final String? picture;
  final String? pictureUrl;
  final String subscriptionStatus;
  final String? subscriptionType;
  final int? subscriptionEnd;
  final int? subscriptionStart;
  final String? coachId;
  final String? referralCode;
  final int referralCoins;
  final List<String> devices;
  final bool chatBanned;
  final int? chatMutedUntil;
  final bool isGuest;
  final String? forceLogoutToken;
  final String? rejectReason;
  final double dailyCals;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  final double? weight;
  final double? height;
  final int? age;
  final String? gender;
  final String? activityLevel;
  final Map<String, dynamic>? dietPrefs;
  final int createdAt;
  final int updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    this.role = 'TRAINEE',
    this.status = 'pending',
    this.program,
    this.programDays,
    this.picture,
    this.pictureUrl,
    this.subscriptionStatus = 'none',
    this.subscriptionType,
    this.subscriptionEnd,
    this.subscriptionStart,
    this.coachId,
    this.referralCode,
    this.referralCoins = 0,
    this.devices = const [],
    this.chatBanned = false,
    this.chatMutedUntil,
    this.isGuest = false,
    this.forceLogoutToken,
    this.rejectReason,
    this.dailyCals = 0,
    this.dailyProtein = 0,
    this.dailyCarbs = 0,
    this.dailyFat = 0,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.dietPrefs,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? 0,
        updatedAt = updatedAt ?? 0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'TRAINEE',
      status: json['status']?.toString() ?? 'pending',
      program: json['program']?.toString(),
      programDays: _toInt(json['programDays']),
      picture: json['picture']?.toString(),
      pictureUrl: json['pictureUrl']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? 'none',
      subscriptionType: json['subscriptionType']?.toString(),
      subscriptionEnd: _toInt(json['subscriptionEnd']),
      subscriptionStart: _toInt(json['subscriptionStart']),
      coachId: json['coachId']?.toString(),
      referralCode: json['referralCode']?.toString(),
      referralCoins: _toInt(json['referralCoins']) ?? 0,
      devices: _toStringList(json['devices']),
      chatBanned: json['chatBanned'] == true || json['chatBanned'] == 'true',
      chatMutedUntil: _toInt(json['chatMutedUntil']),
      isGuest: json['isGuest'] == true || json['isGuest'] == 'true',
      forceLogoutToken: json['forceLogoutToken']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      dailyCals: _toDouble(json['dailyCals']) ?? 0,
      dailyProtein: _toDouble(json['dailyProtein']) ?? 0,
      dailyCarbs: _toDouble(json['dailyCarbs']) ?? 0,
      dailyFat: _toDouble(json['dailyFat']) ?? 0,
      weight: _toDouble(json['weight']),
      height: _toDouble(json['height']),
      age: _toInt(json['age']),
      gender: json['gender']?.toString(),
      activityLevel: json['activityLevel']?.toString(),
      dietPrefs: json['dietPrefs'] is Map
          ? Map<String, dynamic>.from(json['dietPrefs'])
          : null,
      createdAt: _toInt(json['createdAt']) ?? 0,
      updatedAt: _toInt(json['updatedAt']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      if (program != null) 'program': program,
      if (programDays != null) 'programDays': programDays,
      if (picture != null) 'picture': picture,
      if (pictureUrl != null) 'pictureUrl': pictureUrl,
      'subscriptionStatus': subscriptionStatus,
      if (subscriptionType != null) 'subscriptionType': subscriptionType,
      if (subscriptionEnd != null) 'subscriptionEnd': subscriptionEnd,
      if (subscriptionStart != null) 'subscriptionStart': subscriptionStart,
      if (coachId != null) 'coachId': coachId,
      if (referralCode != null) 'referralCode': referralCode,
      'referralCoins': referralCoins,
      'devices': devices,
      'chatBanned': chatBanned,
      if (chatMutedUntil != null) 'chatMutedUntil': chatMutedUntil,
      'isGuest': isGuest,
      if (forceLogoutToken != null) 'forceLogoutToken': forceLogoutToken,
      if (rejectReason != null) 'rejectReason': rejectReason,
      'dailyCals': dailyCals,
      'dailyProtein': dailyProtein,
      'dailyCarbs': dailyCarbs,
      'dailyFat': dailyFat,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (dietPrefs != null) 'dietPrefs': dietPrefs,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? uid, String? email, String? name, String? phone,
    String? role, String? status, String? program, int? programDays,
    String? picture, String? pictureUrl,
    String? subscriptionStatus, String? subscriptionType,
    int? subscriptionEnd, int? subscriptionStart,
    String? coachId, String? referralCode, int? referralCoins,
    List<String>? devices, bool? chatBanned, int? chatMutedUntil,
    bool? isGuest, String? forceLogoutToken, String? rejectReason,
    double? dailyCals, double? dailyProtein, double? dailyCarbs, double? dailyFat,
    double? weight, double? height, int? age, String? gender,
    String? activityLevel, Map<String, dynamic>? dietPrefs,
    int? createdAt, int? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      program: program ?? this.program,
      programDays: programDays ?? this.programDays,
      picture: picture ?? this.picture,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      coachId: coachId ?? this.coachId,
      referralCode: referralCode ?? this.referralCode,
      referralCoins: referralCoins ?? this.referralCoins,
      devices: devices ?? this.devices,
      chatBanned: chatBanned ?? this.chatBanned,
      chatMutedUntil: chatMutedUntil ?? this.chatMutedUntil,
      isGuest: isGuest ?? this.isGuest,
      forceLogoutToken: forceLogoutToken ?? this.forceLogoutToken,
      rejectReason: rejectReason ?? this.rejectReason,
      dailyCals: dailyCals ?? this.dailyCals,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      dietPrefs: dietPrefs ?? this.dietPrefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Role checks ──────────────────────────────────────
  bool get isSuperAdmin => role.toUpperCase() == 'SUPER_ADMIN';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isCoach => role.toUpperCase() == 'COACH';
  bool get isAdminLike {
    final r = role.toUpperCase();
    return r == 'SUPER_ADMIN' || r == 'ADMIN' || r == 'COACH';
  }

  // ── Subscription checks ──────────────────────────────
  bool get isSubscriptionActive {
    if (isAdminLike) return true;
    if (subscriptionStatus != 'active') return false;
    final end = subscriptionEnd;
    if (end != null && end > 0) {
      return DateTime.now().millisecondsSinceEpoch <= end;
    }
    return true;
  }

  bool get isSubscriptionExpired {
    if (isAdminLike) return false;
    if (subscriptionStatus == 'active') {
      final end = subscriptionEnd;
      if (end != null && end > 0) {
        return DateTime.now().millisecondsSinceEpoch > end;
      }
    }
    return subscriptionStatus == 'expired';
  }

  bool featureAllowed(String featureKey, Map<String, dynamic>? subConfig) {
    if (isAdminLike) return true;
    if (!isSubscriptionActive) return false;
    final planId = subscriptionType ?? 'light';
    final plan = subConfig?['plans']?[planId];
    if (plan == null) return true;
    return plan['features']?[featureKey] != false;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}
