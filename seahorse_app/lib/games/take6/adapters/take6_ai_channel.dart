import 'dart:async';
import '../../core/contracts/game_channel.dart';
import '../../core/models/game_action.dart';
import '../domain/take6_ai.dart';
import '../domain/take6_state.dart';

/// 谁是牛头王 - 本地 AI 陪玩信道 (实现 IGameChannel)
/// 负责模拟其他 AI 玩家在收到状态变更时的并发异步思考与动作派发
class Take6AiChannel implements IGameChannel {
  final StreamController<GameAction> _actionController = StreamController<GameAction>.broadcast();
  Take6State? _latestState;

  @override
  Stream<GameAction> get actionStream => _actionController.stream;

  @override
  Future<void> initialize() async {}

  @override
  void broadcastState(dynamic gameState) {
    if (gameState is! Take6State) return;
    _latestState = gameState;

    // 当处于选牌阶段时，驱动所有尚未选牌的 AI 玩家执行思考
    if (gameState.phase == Take6Phase.selectingCard) {
      _triggerAiPickCards(gameState);
    } else if (gameState.phase == Take6Phase.awaitingRowChoice) {
      _triggerAiChooseRow(gameState);
    }
  }

  void _triggerAiPickCards(Take6State state) {
    for (final p in state.players) {
      if (!p.isAi) continue;
      // 已经选过则略过
      if (state.selectedCards[p.id] != null) continue;

      final hand = state.playerHands[p.id] ?? [];
      if (hand.isEmpty) continue;

      // 模拟 400~1000ms 的思考延时，让离线单机体验更加逼真生动
      Future.delayed(Duration(milliseconds: 300 + (hand.length % 3) * 200), () {
        if (_latestState?.phase != Take6Phase.selectingCard) return;
        final chosen = Take6Ai.decideCardToPlay(
          aiPlayerId: p.id,
          hand: hand,
          rows: state.rows,
          personality: p.aiPersonality,
        );

        dispatchAction(GameAction(
          actionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}-${p.id}',
          playerId: p.id,
          actionType: 'PICK_CARD',
          payload: {'cardNumber': chosen.number},
        ));
      });
    }
  }

  void _triggerAiChooseRow(Take6State state) {
    final aiId = state.playerChoosingRowId;
    if (aiId == null) return;
    final aiPlayer = state.players.firstWhere((p) => p.id == aiId, orElse: () => state.players.first);
    if (!aiPlayer.isAi) return;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (_latestState?.phase != Take6Phase.awaitingRowChoice) return;
      final bestRow = Take6Ai.decideRowToTake(rows: state.rows);

      dispatchAction(GameAction(
        actionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}-$aiId',
        playerId: aiId,
        actionType: 'CHOOSE_ROW',
        payload: {'rowIndex': bestRow},
      ));
    });
  }

  @override
  void dispatchAction(GameAction action) {
    _actionController.add(action);
  }

  @override
  Future<void> dispose() async {
    await _actionController.close();
  }
}
