import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/games/core/models/game_action.dart';
import 'package:seahorse_app/games/core/models/game_player.dart';
import 'package:seahorse_app/games/core/models/game_room_model.dart';
import 'package:seahorse_app/games/core/services/game_audio_service.dart';
import 'package:seahorse_app/games/take6/domain/take6_card.dart';
import 'package:seahorse_app/games/take6/domain/take6_engine.dart';
import 'package:seahorse_app/games/take6/domain/take6_state.dart';
import 'package:seahorse_app/games/take6/adapters/take6_local_auditor.dart';
import 'package:seahorse_app/games/liars_dice/domain/dice_bid.dart';
import 'package:seahorse_app/games/liars_dice/domain/dice_rules_engine.dart';
import 'package:seahorse_app/games/liars_dice/domain/dice_state.dart';
import 'package:seahorse_app/games/liars_dice/adapters/dice_local_auditor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('谁是牛头王 (Take 6!) 领域引擎与适配器测试', () {
    test('牛头牌分值算法与104张牌生成测试', () {
      expect(Take6Card.fromNumber(55).bullheads, equals(7));
      expect(Take6Card.fromNumber(11).bullheads, equals(5));
      expect(Take6Card.fromNumber(22).bullheads, equals(5));
      expect(Take6Card.fromNumber(10).bullheads, equals(3));
      expect(Take6Card.fromNumber(20).bullheads, equals(3));
      expect(Take6Card.fromNumber(5).bullheads, equals(2));
      expect(Take6Card.fromNumber(15).bullheads, equals(2));
      expect(Take6Card.fromNumber(7).bullheads, equals(1));
    });

    test('对局初始化、发牌与出牌流程', () {
      final engine = Take6Engine();
      final auditor = Take6LocalAuditor();

      final p1 = GamePlayer(id: 'P1', name: 'Player 1', isAi: false);
      final p2 = GamePlayer(id: 'P2', name: 'Player 2', isAi: true);
      final players = [p1, p2];

      final state = engine.startNewMatch(players: players);
      expect(state.phase, equals(Take6Phase.selectingCard));
      expect(state.rows.length, equals(4));
      expect(state.playerHands['P1']!.length, equals(10));
      expect(state.playerHands['P2']!.length, equals(10));

      // 验证动作校验
      final card1 = state.playerHands['P1']!.first;
      final act1 = GameAction(
        actionId: 'A1',
        playerId: 'P1',
        actionType: 'PICK_CARD',
        payload: {'cardNumber': card1.number},
      );
      final isValid = auditor.validateAction(engine.state, act1);
      expect(isValid, isTrue);

      // 玩家1出牌
      engine.playerPickCard('P1', card1);
      expect(engine.state.selectedCards['P1'], equals(card1));
    });
  });

  group('大话骰 (Liar\'s Dice) 领域引擎与适配器测试', () {
    test('出价规则校验 (isStrictlyHigherThan)', () {
      final bid1 = DiceBid(bidderId: 'P1', bidderName: 'P1', count: 3, face: 2);
      final bidSame = DiceBid(bidderId: 'P2', bidderName: 'P2', count: 3, face: 2);
      final bidHigherFace = DiceBid(bidderId: 'P2', bidderName: 'P2', count: 3, face: 3);
      final bidHigherCount = DiceBid(bidderId: 'P2', bidderName: 'P2', count: 4, face: 2);
      final bidLower = DiceBid(bidderId: 'P2', bidderName: 'P2', count: 2, face: 5);

      expect(bidSame.isStrictlyHigherThan(bid1), isFalse);
      expect(bidHigherFace.isStrictlyHigherThan(bid1), isTrue);
      expect(bidHigherCount.isStrictlyHigherThan(bid1), isTrue);
      expect(bidLower.isStrictlyHigherThan(bid1), isFalse);
    });

    test('摇骰、顺时针出价与开盅判决', () {
      final engine = DiceRulesEngine();
      final auditor = DiceLocalAuditor(engine: engine);

      final p1 = GamePlayer(id: 'P1', name: 'Alice', isAi: false);
      final p2 = GamePlayer(id: 'P2', name: 'Bob', isAi: true);
      final players = [p1, p2];

      engine.startNewRound(players: players, starterIndex: 0);
      expect(engine.state.phase, equals(DicePhase.bidding));
      expect(engine.state.currentPlayer.id, equals('P1'));

      // P1 叫点: 3 个 2
      final bidAction = GameAction(
        actionId: 'B1',
        playerId: 'P1',
        actionType: 'BID',
        payload: {'count': 3, 'face': 2, 'isPure': false},
      );
      final bidRes = auditor.executeAction(bidAction);
      expect(bidRes.isSuccess, isTrue);

      expect(engine.state.currentBid?.count, equals(3));
      expect(engine.state.currentBid?.face, equals(2));
      expect(engine.state.currentPlayer.id, equals('P2'));

      // P2 开盅质疑
      final chalAction = GameAction(
        actionId: 'C1',
        playerId: 'P2',
        actionType: 'CHALLENGE',
        payload: {},
      );
      final chalRes = auditor.executeAction(chalAction);
      expect(chalRes.isSuccess, isTrue);

      expect(engine.state.phase, equals(DicePhase.challenged));
      expect(engine.state.lastResult, isNotNull);
      expect(engine.state.lastResult?.challengerId, equals('P2'));
    });
  });

  group('房间号与AI席位调配测试 (GameRoomModel)', () {
    test('房间号生成与初始人数校验', () {
      final host = GamePlayer(id: 'H1', name: '房主小张', isAi: false);
      final room = GameRoomModel.create(gameType: 'take6', hostPlayer: host);

      expect(room.roomCode.length, equals(6));
      expect(room.players.length, equals(1));
      expect(room.humanCount, equals(1));
      expect(room.aiCount, equals(0));
      expect(room.canStartGame, isFalse); // 1人不可开局
    });

    test('动态增删改AI机器人席位', () {
      final host = GamePlayer(id: 'H1', name: '房主小张', isAi: false);
      final room = GameRoomModel.create(gameType: 'take6', hostPlayer: host);

      // 添加一个 AI
      final added = room.addAiPlayer(customName: '阿尔法狗', personality: 'AGGRESSIVE');
      expect(added, isTrue);
      expect(room.players.length, equals(2));
      expect(room.canStartGame, isTrue);

      final ai = room.players.firstWhere((p) => p.isAi);
      expect(ai.name, equals('阿尔法狗'));
      expect(ai.aiPersonality, equals('AGGRESSIVE'));

      // 修改 AI 性格
      room.updateAiPersonality(ai.id, 'BLUFF_MASTER');
      final updatedAi = room.players.firstWhere((p) => p.id == ai.id);
      expect(updatedAi.aiPersonality, equals('BLUFF_MASTER'));

      // 删除 AI
      final removed = room.removeAiPlayer(ai.id);
      expect(removed, isTrue);
      expect(room.aiCount, equals(0));
      expect(room.canStartGame, isFalse);
    });

    test('手机号邀请好友加入房间', () {
      final host = GamePlayer(id: 'H1', name: '房主小张', isAi: false);
      final room = GameRoomModel.create(gameType: 'liars_dice', hostPlayer: host);

      final invited = room.inviteFriendByPhone('13800138000', friendName: '老李');
      expect(invited, isTrue);
      expect(room.humanCount, equals(2));
      expect(room.canStartGame, isTrue);
      expect(room.players.last.name, equals('老李'));
      expect(room.players.last.isAi, isFalse);
    });

    test('一键补齐AI与清空AI', () {
      final host = GamePlayer(id: 'H1', name: '房主小张', isAi: false);
      final room = GameRoomModel.create(gameType: 'take6', hostPlayer: host);

      room.fillAiToCount(4);
      expect(room.players.length, equals(4));
      expect(room.aiCount, equals(3));

      room.clearAllAi();
      expect(room.players.length, equals(1));
      expect(room.aiCount, equals(0));
    });
  });

  group('音频与音效服务测试 (GameAudioService)', () {
    test('合成音频初始化与开关控制', () async {
      final audio = GameAudioService();
      await audio.initialize();

      expect(audio.isBgmEnabled, isTrue);
      expect(audio.isSfxEnabled, isTrue);

      audio.toggleBgm();
      expect(audio.isBgmEnabled, isFalse);
      audio.toggleBgm();
      expect(audio.isBgmEnabled, isTrue);

      audio.setBgmVolume(0.3);
      expect(audio.bgmVolume, closeTo(0.3, 0.01));
    });
  });
}
