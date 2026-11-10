import 'dart:async';
import 'dart:math';
import '../../core/models/game_player.dart';
import 'take6_card.dart';
import 'take6_row.dart';
import 'take6_state.dart';

/// 谁是牛头王 - 纯领域内核引擎 (Pure Dart Domain Engine)
/// 零 Flutter UI / 零外部信道依赖，负责桌游全部运转规则状态机
class Take6Engine {
  late Take6State _state;
  final StreamController<Take6State> _stateController = StreamController<Take6State>.broadcast();

  Take6State get state => _state;
  Stream<Take6State> get stateStream => _stateController.stream;

  /// 初始化一整局游戏
  Take6State startNewMatch({
    required List<GamePlayer> players,
    int handSize = 10,
  }) {
    assert(players.length >= 2 && players.length <= 10, '玩家人数需为 2~10 人');

    final deck = Take6Card.generateDeck()..shuffle(Random());

    // 1. 发桌面 4 行底牌
    final rows = <Take6Row>[];
    for (int i = 0; i < 4; i++) {
      rows.add(Take6Row(rowIndex: i, cards: [deck.removeLast()]));
    }

    // 2. 发手牌 (默认每人 10 张并排好序)
    final playerHands = <String, List<Take6Card>>{};
    for (final p in players) {
      final hand = deck.sublist(0, handSize)..sort();
      deck.removeRange(0, handSize);
      playerHands[p.id] = hand;
    }

    _state = Take6State(
      roundId: 'T6-${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      rows: rows,
      playerHands: playerHands,
      selectedCards: {for (var p in players) p.id: null},
      penaltyScores: {for (var p in players) p.id: 0},
      currentTurn: 1,
      phase: Take6Phase.selectingCard,
      eventLogs: ['🐮 谁是牛头王开局！桌面已布设 4 移行牌，每位玩家发放 10 张手牌。'],
    );

    _emit();
    return _state;
  }

  /// 玩家 (人类或 AI) 选定出牌
  bool playerPickCard(String playerId, Take6Card card) {
    if (_state.phase != Take6Phase.selectingCard) return false;
    final hand = _state.playerHands[playerId];
    if (hand == null || !hand.contains(card)) return false;

    _state.selectedCards[playerId] = card;

    // 若所有人均已选定，自动推进至亮牌翻转
    if (_state.isAllCardsSelected) {
      _triggerRevealAndQueue();
    } else {
      _emit();
    }
    return true;
  }

  /// 全部选好后翻牌并组装入行队列
  void _triggerRevealAndQueue() {
    _state.phase = Take6Phase.revealing;

    final queue = <PlayedCardEntry>[];
    for (final p in _state.players) {
      final card = _state.selectedCards[p.id]!;
      // 从手牌中扣减
      _state.playerHands[p.id]!.remove(card);
      queue.add(PlayedCardEntry(playerId: p.id, playerName: p.name, card: card));
    }

    // 核心规则：按牌面从小到大排序依次入行
    queue.sort();
    _state.pendingResolveQueue.clear();
    _state.pendingResolveQueue.addAll(queue);

    _state.eventLogs.add(
      '🃏 本回合翻牌：${queue.map((e) => '${e.playerName}[${e.card.number}]').join('，')}',
    );

    _emit();
    // 开始依次入行处理
    _resolveNextCardInQueue();
  }

  /// 顺序解决入行队列中的下一张牌
  void _resolveNextCardInQueue() {
    if (_state.pendingResolveQueue.isEmpty) {
      _finishTurn();
      return;
    }

    final entry = _state.pendingResolveQueue.removeAt(0);
    _state.currentResolvingEntry = entry;
    _state.phase = Take6Phase.resolving;

    final card = entry.card;

    // 寻找所有末尾牌小于 card 的行中，差值最小的那一行
    int bestRowIndex = -1;
    int minDiff = 9999;

    for (int i = 0; i < _state.rows.length; i++) {
      final rowLast = _state.rows[i].lastCard.number;
      if (card.number > rowLast) {
        final diff = card.number - rowLast;
        if (diff < minDiff) {
          minDiff = diff;
          bestRowIndex = i;
        }
      }
    }

    // 情况 A: 牌比当前 4 行所有末尾牌都要小！必须由玩家选择收走任意一行
    if (bestRowIndex == -1) {
      _state.phase = Take6Phase.awaitingRowChoice;
      _state.playerChoosingRowId = entry.playerId;
      _state.eventLogs.add(
        '⚠️ 【${entry.playerName}】打出牌 [${card.number}] 小于所有行末尾牌，必须任选一行收走并计入牛头惩罚！',
      );
      _emit();
      return;
    }

    // 情况 B: 找到了差值最小的目标行
    final targetRow = _state.rows[bestRowIndex];

    // 判断放入后是否爆行 (即将成为第 6 张牌)
    if (targetRow.willOverflowWith(card)) {
      final penaltyCards = targetRow.takeRowAndReset(card);
      final addedBullheads = penaltyCards.fold(0, (sum, c) => sum + c.bullheads);
      _state.penaltyScores[entry.playerId] = (_state.penaltyScores[entry.playerId] ?? 0) + addedBullheads;

      _state.eventLogs.add(
        '💥 爆行！【${entry.playerName}】的牌 [${card.number}] 成为第 6 张牌，收走第 ${bestRowIndex + 1} 行前 5 张牌，吃进 🐮x$addedBullheads！',
      );
    } else {
      // 正常入行，未爆行
      targetRow.append(card);
      _state.eventLogs.add(
        '👉 【${entry.playerName}】的牌 [${card.number}] 顺利入驻第 ${bestRowIndex + 1} 行 (当前 ${targetRow.count}/5)。',
      );
    }

    _emit();
    // 继续解决队列下一张
    _resolveNextCardInQueue();
  }

  /// 牌比所有末尾牌都小时，玩家做出吃行选择 (行索引 0~3)
  bool playerChooseRowToTake(String playerId, int rowIndex) {
    if (_state.phase != Take6Phase.awaitingRowChoice) return false;
    if (_state.playerChoosingRowId != playerId) return false;
    if (rowIndex < 0 || rowIndex >= _state.rows.length) return false;

    final entry = _state.currentResolvingEntry;
    if (entry == null) return false;

    final targetRow = _state.rows[rowIndex];
    final penaltyCards = targetRow.takeRowAndReset(entry.card);
    final addedBullheads = penaltyCards.fold(0, (sum, c) => sum + c.bullheads);
    _state.penaltyScores[playerId] = (_state.penaltyScores[playerId] ?? 0) + addedBullheads;

    _state.eventLogs.add(
      '🧹 【${entry.playerName}】主动收走第 ${rowIndex + 1} 行全量纸牌，承受 🐮x$addedBullheads 牛头惩罚，[${entry.card.number}] 成为该行新底牌。',
    );

    _state.playerChoosingRowId = null;
    _emit();

    // 解决下一张
    _resolveNextCardInQueue();
    return true;
  }

  /// 一回合所有牌放完后，检查手牌是否打空
  void _finishTurn() {
    _state.currentResolvingEntry = null;
    _state.selectedCards.updateAll((key, value) => null);

    final isHandEmpty = _state.playerHands.values.every((h) => h.isEmpty);

    if (isHandEmpty || _state.currentTurn >= 10) {
      _state.phase = Take6Phase.gameOver;
      // 结算最终排位 (牛头惩罚数越少越靠前)
      final ranking = List<GamePlayer>.from(_state.players);
      ranking.sort((a, b) => (_state.penaltyScores[a.id] ?? 0).compareTo(_state.penaltyScores[b.id] ?? 0));
      final winner = ranking.first;
      _state.eventLogs.add(
        '🏆 游戏结束！获胜者为【${winner.name}】，牛头惩罚最少 (${_state.penaltyScores[winner.id]} 个牛头)！',
      );
    } else {
      _state.currentTurn += 1;
      _state.phase = Take6Phase.selectingCard;
      _state.eventLogs.add('🔔 第 ${_state.currentTurn} 回合开始，请各位玩家选择手牌！');
    }

    _emit();
  }

  void _emit() {
    _stateController.add(_state.copy());
  }

  void dispose() {
    _stateController.close();
  }
}
