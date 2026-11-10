import 'dart:math';
import 'game_player.dart';

/// 聚会桌游房间会话实体 (Game Room Session Model)
/// 承载 6 位幸运房间号、玩家席位、AI 机器人动态调配与好友手机号邀请机制
class GameRoomModel {
  final String roomCode;
  final String gameType; // 'take6' or 'liars_dice'
  final String hostPlayerId;
  final String storeName;
  final String tableNo;
  final List<GamePlayer> players;
  final DateTime createdAt;

  GameRoomModel({
    required this.roomCode,
    required this.gameType,
    required this.hostPlayerId,
    this.storeName = '离线聚会吧',
    this.tableNo = '888',
    List<GamePlayer>? players,
    DateTime? createdAt,
  })  : players = players ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 快速创建全新 6 位数字房间号房间 (例如: 882619)
  factory GameRoomModel.create({
    required String gameType,
    required GamePlayer hostPlayer,
    String storeName = '离线聚会吧',
    String tableNo = '888',
  }) {
    final rand = Random();
    // 生成 6 位不以 0 开头的房间号
    final code = (100000 + rand.nextInt(900000)).toString();
    return GameRoomModel(
      roomCode: code,
      gameType: gameType,
      hostPlayerId: hostPlayer.id,
      storeName: storeName,
      tableNo: tableNo,
      players: [hostPlayer],
    );
  }

  /// 当前人类真人玩家数量
  int get humanCount => players.where((p) => !p.isAi).length;

  /// 当前 AI 机器人数量
  int get aiCount => players.where((p) => p.isAi).length;

  /// 是否满足开局条件 (至少 2 人，牛头王上限 10 人，大话骰上限 8 人)
  bool get canStartGame => players.length >= 2;

  int get maxCapacity => gameType == 'take6' ? 10 : 8;

  /// 动态增加一名 AI 玩家
  bool addAiPlayer({String? customName, String personality = 'BALANCED'}) {
    if (players.length >= maxCapacity) return false;

    final defaultAiNames = [
      '阿强 (AI)',
      '翠花 (AI)',
      '老陈 (AI)',
      '小智 (AI)',
      'Lucy (AI)',
      '摇骰鬼才 (AI)',
      '心机阿财 (AI)',
      '冷面刀客 (AI)',
      '赌圣九哥 (AI)',
    ];

    final existingNames = players.map((p) => p.name).toSet();
    final name = customName ??
        defaultAiNames.firstWhere(
          (n) => !existingNames.contains(n),
          orElse: () => 'AI-${players.length + 1}号',
        );

    final aiPlayer = GamePlayer(
      id: 'AI-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
      name: name,
      isAi: true,
      aiPersonality: personality,
    );

    players.add(aiPlayer);
    return true;
  }

  /// 删除指定 AI 席位
  bool removeAiPlayer(String playerId) {
    final index = players.indexWhere((p) => p.id == playerId && p.isAi);
    if (index != -1) {
      players.removeAt(index);
      return true;
    }
    return false;
  }

  /// 修改指定 AI 玩家的难度与性格风格
  bool updateAiPersonality(String playerId, String newPersonality) {
    final index = players.indexWhere((p) => p.id == playerId && p.isAi);
    if (index != -1) {
      final old = players[index];
      players[index] = GamePlayer(
        id: old.id,
        name: old.name,
        isAi: true,
        aiPersonality: newPersonality,
      );
      return true;
    }
    return false;
  }

  /// 一键将空位用 AI 机器人补齐到目标人数
  void fillAiToCount(int targetCount) {
    final count = targetCount.clamp(2, maxCapacity);
    while (players.length < count) {
      addAiPlayer();
    }
  }

  /// 一键清空所有 AI，只保留真实真人玩家
  void clearAllAi() {
    players.removeWhere((p) => p.isAi);
  }

  /// 通过手机号邀请好友加入房间
  bool inviteFriendByPhone(String phone, {String? friendName}) {
    if (players.length >= maxCapacity) return false;
    final shortPhone = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    final name = friendName ?? '好友($shortPhone)';

    final friend = GamePlayer(
      id: 'HUMAN-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isAi: false,
    );
    players.add(friend);
    return true;
  }
}
