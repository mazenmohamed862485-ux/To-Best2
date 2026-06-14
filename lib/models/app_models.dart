// ── Chat Message ──────────────────────────────────────
class ChatMessage {
  final String id;
  final String uid;
  final String name;
  final String? picture;
  final String role;
  final String text;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final int ts;
  final bool deleted;
  final bool edited;
  final bool pinned;

  const ChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    this.picture,
    this.role = 'TRAINEE',
    required this.text,
    this.fileUrl,
    this.fileType,
    this.fileName,
    required this.ts,
    this.deleted = false,
    this.edited = false,
    this.pinned = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      picture: json['picture']?.toString(),
      role: json['role']?.toString() ?? 'TRAINEE',
      text: json['text']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString(),
      fileType: json['fileType']?.toString(),
      fileName: json['fileName']?.toString(),
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      deleted: json['deleted'] == true,
      edited: json['edited'] == true,
      pinned: json['pinned'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'name': name,
    if (picture != null) 'picture': picture,
    'role': role,
    'text': text,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (fileType != null) 'fileType': fileType,
    if (fileName != null) 'fileName': fileName,
    'ts': ts,
    if (deleted) 'deleted': deleted,
    if (edited) 'edited': edited,
    if (pinned) 'pinned': pinned,
  };

  bool get isAdminLike {
    final r = role.toUpperCase();
    return r == 'SUPER_ADMIN' || r == 'ADMIN' || r == 'COACH';
  }
}

// ── Meal Entry ────────────────────────────────────────
class MealEntry {
  final String id;
  final String uid;
  final String date;
  final String mealType; // breakfast/lunch/dinner/snack
  final String foodName;
  final double amount; // grams
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int ts;

  const MealEntry({
    required this.id,
    required this.uid,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    int? ts,
  }) : ts = ts ?? 0;

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      mealType: json['mealType']?.toString() ?? 'snack',
      foodName: json['foodName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      ts: (json['ts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'date': date,
    'mealType': mealType,
    'foodName': foodName,
    'amount': amount,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'ts': ts,
  };
}

// ── Daily Totals ──────────────────────────────────────
class DailyNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double water; // ml

  const DailyNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.water = 0,
  });

  DailyNutrition operator +(DailyNutrition other) {
    return DailyNutrition(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      water: water + other.water,
    );
  }
}

// ── Food Item ─────────────────────────────────────────
class FoodItem {
  final String name;
  final String nameEn;
  final double cals;   // per 100g
  final double p;      // protein
  final double c;      // carbs
  final double f;      // fat
  final double? fiber;
  final String? category;
  final int? cost;     // 1-5 scale
  final bool isVeg;

  const FoodItem({
    required this.name,
    this.nameEn = '',
    required this.cals,
    this.p = 0,
    this.c = 0,
    this.f = 0,
    this.fiber,
    this.category,
    this.cost,
    this.isVeg = false,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      cals: (json['cals'] as num?)?.toDouble() ?? 0,
      p: (json['p'] as num?)?.toDouble() ?? 0,
      c: (json['c'] as num?)?.toDouble() ?? 0,
      f: (json['f'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      category: json['cat']?.toString(),
      cost: (json['cost'] as num?)?.toInt(),
      isVeg: json['veg'] == true,
    );
  }

  MealEntry toMealEntry({
    required String uid,
    required String date,
    required String mealType,
    required double amount,
    required String id,
  }) {
    final factor = amount / 100;
    return MealEntry(
      id: id,
      uid: uid,
      date: date,
      mealType: mealType,
      foodName: name,
      amount: amount,
      calories: cals * factor,
      protein: p * factor,
      carbs: c * factor,
      fat: f * factor,
      fiber: (fiber ?? 0) * factor,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ── Measurement ───────────────────────────────────────
class Measurement {
  final String uid;
  final String date;
  final double? weight;
  final double? waist;
  final double? chest;
  final double? hips;
  final double? arms;
  final double? thighs;
  final double? neck;
  final double? shoulders;
  final double? bodyFat;
  final String? notes;

  const Measurement({
    required this.uid,
    required this.date,
    this.weight,
    this.waist,
    this.chest,
    this.hips,
    this.arms,
    this.thighs,
    this.neck,
    this.shoulders,
    this.bodyFat,
    this.notes,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      uid: json['uid']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      arms: (json['arms'] as num?)?.toDouble(),
      thighs: (json['thighs'] as num?)?.toDouble(),
      neck: (json['neck'] as num?)?.toDouble(),
      shoulders: (json['shoulders'] as num?)?.toDouble(),
      bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'date': date,
    if (weight != null) 'weight': weight,
    if (waist != null) 'waist': waist,
    if (chest != null) 'chest': chest,
    if (hips != null) 'hips': hips,
    if (arms != null) 'arms': arms,
    if (thighs != null) 'thighs': thighs,
    if (neck != null) 'neck': neck,
    if (shoulders != null) 'shoulders': shoulders,
    if (bodyFat != null) 'bodyFat': bodyFat,
    if (notes != null) 'notes': notes,
  };
}

// ── Subscription Request ──────────────────────────────
class SubscriptionRequest {
  final String id;
  final String uid;
  final String userName;
  final String planId;
  final int months;
  final double amount;
  final String? promoCode;
  final String? paymentProofUrl;
  final String status; // pending/approved/rejected
  final int ts;
  final String? notes;

  const SubscriptionRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.planId,
    required this.months,
    required this.amount,
    this.promoCode,
    this.paymentProofUrl,
    this.status = 'pending',
    required this.ts,
    this.notes,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequest(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      planId: json['planId']?.toString() ?? 'light',
      months: (json['months'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      promoCode: json['promoCode']?.toString(),
      paymentProofUrl: json['paymentProofUrl']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'userName': userName,
    'planId': planId,
    'months': months,
    'amount': amount,
    if (promoCode != null) 'promoCode': promoCode,
    if (paymentProofUrl != null) 'paymentProofUrl': paymentProofUrl,
    'status': status,
    'ts': ts,
    if (notes != null) 'notes': notes,
  };
}

// ── Notification ──────────────────────────────────────
class AppNotification {
  final String id;
  final String uid;
  final String icon;
  final String title;
  final String body;
  final int ts;
  final bool read;

  const AppNotification({
    required this.id,
    required this.uid,
    this.icon = '🔔',
    required this.title,
    required this.body,
    required this.ts,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🔔',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      read: json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'icon': icon,
    'title': title,
    'body': body,
    'ts': ts,
    'read': read,
  };
}

// ── Sync Queue Item ───────────────────────────────────
class SyncQueueItem {
  final int? id;
  final String action;
  final String key;
  final String uid;
  final String data; // JSON string
  final int ts;
  final int retries;

  const SyncQueueItem({
    this.id,
    required this.action,
    required this.key,
    required this.uid,
    required this.data,
    int? ts,
    this.retries = 0,
  }) : ts = ts ?? 0;

  Map<String, dynamic> toJson() => {
    'action': action,
    'key': key,
    'uid': uid,
    'data': data,
    'ts': ts,
    'retries': retries,
  };
}

// ── Ban Entry ─────────────────────────────────────────
class BanEntry {
  final String id;
  final String? email;
  final String? phone;
  final String? deviceId;
  final String? accountId;
  final String reason;
  final int ts;
  final String bannedBy;

  const BanEntry({
    required this.id,
    this.email,
    this.phone,
    this.deviceId,
    this.accountId,
    this.reason = '',
    required this.ts,
    required this.bannedBy,
  });

  factory BanEntry.fromJson(Map<String, dynamic> json) {
    return BanEntry(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      deviceId: json['deviceId']?.toString(),
      accountId: json['accountId']?.toString(),
      reason: json['reason']?.toString() ?? '',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      bannedBy: json['bannedBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (deviceId != null) 'deviceId': deviceId,
    if (accountId != null) 'accountId': accountId,
    'reason': reason,
    'ts': ts,
    'bannedBy': bannedBy,
  };
}

// ── Evaluation Types ──────────────────────────────────
enum EvalType { s1, s2, s3, rv, gd, st, ws, dn, beg }

class EvalResult {
  final EvalType type;
  final String label;

  const EvalResult({required this.type, required this.label});
}
