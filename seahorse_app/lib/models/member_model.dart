import '../core/constants/member_level_helper.dart';

class TimesCardItem {
  final String cardNo;
  final String templateName;
  final String projectName;
  int remainingCount;
  final int totalCount;
  final String expireDate;

  TimesCardItem({
    required this.cardNo,
    required this.templateName,
    required this.projectName,
    required this.remainingCount,
    required this.totalCount,
    required this.expireDate,
  });

  factory TimesCardItem.fromJson(Map<String, dynamic> json) {
    return TimesCardItem(
      cardNo: json['cardNo'] ?? '',
      templateName: json['templateName'] ?? '超值体验次卡',
      projectName: json['projectName'] ?? '招牌核心项目',
      remainingCount: json['remainingCount'] ?? 10,
      totalCount: json['totalCount'] ?? 10,
      expireDate: json['expireDate'] ?? '2027-12-31',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardNo': cardNo,
      'templateName': templateName,
      'projectName': projectName,
      'remainingCount': remainingCount,
      'totalCount': totalCount,
      'expireDate': expireDate,
    };
  }
}

class MemberModel {
  final int id;
  final String memberNo;
  String name;
  String phone;
  String gender;
  double balance;
  int points;
  String levelName;
  String rawLevel;
  double discountRate;
  final String registerDate;
  double totalSpent;
  int visitCount;
  String birthday;
  String notes;
  double rewardAmount;
  final List<TimesCardItem> timesCards;

  MemberModel({
    required this.id,
    required this.memberNo,
    required this.name,
    required this.phone,
    this.gender = 'MALE',
    this.balance = 0.0,
    this.points = 0,
    this.levelName = '普卡会员',
    this.rawLevel = 'REGULAR',
    this.discountRate = 1.0,
    required this.registerDate,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    this.birthday = '',
    this.notes = '',
    this.rewardAmount = 0.0,
    this.timesCards = const [],
  });

  String get cardNo => memberNo;

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    var cardsJson = json['timesCards'] as List? ?? [];
    List<TimesCardItem> cards = cardsJson.map((e) => TimesCardItem.fromJson(e)).toList();

    String regDate = '';
    if (json['registerDate'] != null && json['registerDate'].toString().isNotEmpty) {
      regDate = json['registerDate'].toString();
    } else if (json['createdAt'] != null) {
      regDate = json['createdAt'].toString().split('T')[0];
    }

    final rawLevel = (json['level'] ?? json['levelName'] ?? 'REGULAR').toString();
    String parsedLevelName = '普卡会员';
    double rate = 1.0;

    if (rawLevel.contains('DIAMOND') || rawLevel.contains('钻') || rawLevel.contains('黑金')) {
      parsedLevelName = '黑钻至尊卡';
      rate = 0.80;
    } else if (rawLevel.contains('PLATINUM') || rawLevel.contains('白金') || rawLevel.contains('铂金')) {
      parsedLevelName = '至尊白金卡';
      rate = 0.85;
    } else if (rawLevel == 'VIP' || rawLevel.contains('VIP') || rawLevel.contains('尊享')) {
      parsedLevelName = 'VIP尊享卡';
      rate = 0.88;
    } else if (rawLevel.contains('GOLD') || rawLevel.contains('金')) {
      parsedLevelName = '黄金VIP卡';
      rate = 0.90;
    } else if (rawLevel.contains('SILVER') || rawLevel.contains('银')) {
      parsedLevelName = '荣耀银卡';
      rate = 0.95;
    } else if (rawLevel.isNotEmpty && rawLevel != 'REGULAR') {
      parsedLevelName = rawLevel;
    }

    if (json['discountRate'] != null) {
      rate = json['discountRate'] is num
          ? (json['discountRate'] as num).toDouble()
          : (double.tryParse(json['discountRate'].toString()) ?? rate);
    }

    final dynamic rawBalance = json['balance'] ?? json['totalBalance'];
    final double parsedBalance = rawBalance != null
        ? (rawBalance is num ? rawBalance.toDouble() : (double.tryParse(rawBalance.toString()) ?? 0.0))
        : 0.0;

    final dynamic rawSpent = json['totalSpent'];
    final double parsedSpent = rawSpent != null
        ? (rawSpent is num ? rawSpent.toDouble() : (double.tryParse(rawSpent.toString()) ?? 0.0))
        : 0.0;

    final dynamic rawReward = json['rewardAmount'];
    final double parsedReward = rawReward != null
        ? (rawReward is num ? rawReward.toDouble() : (double.tryParse(rawReward.toString()) ?? 0.0))
        : 0.0;

    return MemberModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      memberNo: json['memberNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'MALE',
      balance: parsedBalance,
      points: json['points'] is num ? (json['points'] as num).toInt() : (int.tryParse(json['points']?.toString() ?? '0') ?? 0),
      levelName: json['levelName'] != null ? json['levelName'].toString() : parsedLevelName,
      rawLevel: rawLevel,
      discountRate: rate,
      registerDate: regDate,
      totalSpent: parsedSpent,
      visitCount: json['visitCount'] is num ? (json['visitCount'] as num).toInt() : (int.tryParse(json['visitCount']?.toString() ?? '0') ?? 0),
      birthday: json['birthday']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      rewardAmount: parsedReward,
      timesCards: cards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberNo': memberNo,
      'name': name,
      'phone': phone,
      'gender': gender,
      'balance': balance,
      'points': points,
      'level': rawLevel,
      'levelName': levelName,
      'discountRate': discountRate,
      'registerDate': registerDate,
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'birthday': birthday,
      'notes': notes,
      'rewardAmount': rewardAmount,
      'timesCards': timesCards.map((e) => e.toJson()).toList(),
    };
  }

  /// 下一等级名称
  String? get nextLevelName => MemberLevelHelper.getNextRule(points)?.levelName;

  /// 距升级下一等级差额
  int get pointsToNext => MemberLevelHelper.getPointsToNext(points);

  /// 升级进度比率 (0.0 ~ 1.0)
  double get growthProgress => MemberLevelHelper.getProgressRatio(points);
}
