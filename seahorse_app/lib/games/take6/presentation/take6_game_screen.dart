import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/contracts/game_channel.dart';
import '../../core/contracts/game_host_context.dart';
import '../../core/contracts/game_reward_bridge.dart';
import '../../core/models/game_action.dart';
import '../../core/models/game_player.dart';
import '../../core/services/game_audio_service.dart';
import '../domain/take6_card.dart';
import '../domain/take6_engine.dart';
import '../domain/take6_state.dart';
import '../adapters/take6_ai_channel.dart';
import 'widgets/take6_card_widget.dart';
import 'widgets/take6_hand_widget.dart';
import 'widgets/take6_row_widget.dart';

/// 谁是牛头王 - 完整游戏主屏幕 (整洁架构表现层，完全依赖注入)
class Take6GameScreen extends StatefulWidget {
  final IGameChannel channel;
  final IGameRewardBridge rewardBridge;
  final IGameHostContext hostContext;
  final List<GamePlayer> players;
  final String localPlayerId;
  final String? roomCode;

  const Take6GameScreen({
    super.key,
    required this.channel,
    required this.rewardBridge,
    required this.hostContext,
    required this.players,
    required this.localPlayerId,
    this.roomCode,
  });

  /// 快速构建工厂方法（默认单机/离线 AI 对战）
  static Widget createOffline({
    required List<GamePlayer> players,
    required String localPlayerId,
    required IGameRewardBridge rewardBridge,
    required IGameHostContext hostContext,
    String? roomCode,
  }) {
    final channel = Take6AiChannel();
    return Take6GameScreen(
      channel: channel,
      rewardBridge: rewardBridge,
      hostContext: hostContext,
      players: players,
      localPlayerId: localPlayerId,
      roomCode: roomCode,
    );
  }

  @override
  State<Take6GameScreen> createState() => _Take6GameScreenState();
}

class _Take6GameScreenState extends State<Take6GameScreen> {
  late final Take6Engine _engine;
  StreamSubscription<Take6State>? _stateSub;
  StreamSubscription<GameAction>? _actionSub;

  Take6Card? _selectedCard;
  final ScrollController _logScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _engine = Take6Engine();

    // 监听引擎内部状态流
    _stateSub = _engine.stateStream.listen((state) {
      if (mounted) {
        setState(() {});
        widget.channel.broadcastState(state);
        _handleStateEvents(state);
      }
    });

    // 监听信道输入的动作指令 (包含本地玩家、本地 AI 或联机远端)
    _actionSub = widget.channel.actionStream.listen((action) {
      if (action.actionType == 'PICK_CARD') {
        final cardNum = action.payload['cardNumber'] as int;
        _engine.playerPickCard(action.playerId, Take6Card.fromNumber(cardNum));
      } else if (action.actionType == 'CHOOSE_ROW') {
        final rowIndex = action.payload['rowIndex'] as int;
        _engine.playerChooseRowToTake(action.playerId, rowIndex);
      }
    });

    // 启动信道并开局
    widget.channel.initialize();
    _engine.startNewMatch(players: widget.players);
    GameAudioService().startBgm();
  }

  void _handleStateEvents(Take6State state) {
    // 自动滚动裁判日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollCtrl.hasClients) {
        _logScrollCtrl.animateTo(
          _logScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    // 游戏结束结算
    if (state.phase == Take6Phase.gameOver) {
      final ranking = List<GamePlayer>.from(state.players)
        ..sort((a, b) => (state.penaltyScores[a.id] ?? 0).compareTo(state.penaltyScores[b.id] ?? 0));
      
      widget.rewardBridge.onMatchFinished(
        gameCode: 'TAKE_6',
        rankedPlayers: ranking,
        summary: {
          'winnerId': ranking.first.id,
          'winnerName': ranking.first.name,
          'penaltyScores': state.penaltyScores,
        },
      );

      if (ranking.isNotEmpty && ranking.first.id == widget.localPlayerId) {
        GameAudioService().playSound('victory');
      } else {
        GameAudioService().playSound('defeat');
      }
    }
  }

  void _copyRoomCode() {
    if (widget.roomCode == null) return;
    final inviteText = '【海马聚会桌游】谁是牛头王开局啦！\n👉 房间号：${widget.roomCode}\n快打开海马 App 加入我们！';
    Clipboard.setData(ClipboardData(text: inviteText));
    GameAudioService().playSound('bid_ding');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 房间号 ${widget.roomCode} 邀请信息已复制！'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    GameAudioService().stopBgm();
    _stateSub?.cancel();
    _actionSub?.cancel();
    _engine.dispose();
    widget.channel.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  void _onConfirmPlay() {
    if (_selectedCard == null) return;
    widget.hostContext.playSound('card_play');
    widget.hostContext.triggerHapticFeedback();

    widget.channel.dispatchAction(GameAction(
      actionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      playerId: widget.localPlayerId,
      actionType: 'PICK_CARD',
      payload: {'cardNumber': _selectedCard!.number},
    ));

    setState(() {
      _selectedCard = null;
    });
  }

  void _onSelectRowToTake(int rowIndex) {
    widget.hostContext.playSound('bull_penalty');
    widget.hostContext.triggerHapticFeedback(heavy: true);

    widget.channel.dispatchAction(GameAction(
      actionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      playerId: widget.localPlayerId,
      actionType: 'CHOOSE_ROW',
      payload: {'rowIndex': rowIndex},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = _engine.state;
    final myHand = state.playerHands[widget.localPlayerId] ?? [];
    final mySelectedCard = state.selectedCards[widget.localPlayerId];
    final isMyTurnToChooseRow = state.phase == Take6Phase.awaitingRowChoice &&
        state.playerChoosingRowId == widget.localPlayerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // 护眼柔和浅米灰
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          tooltip: '返回大厅',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              '🐮 谁是牛头王 (Take 6!)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            if (widget.roomCode != null)
              GestureDetector(
                onTap: _copyRoomCode,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.meeting_room, color: Color(0xFFD97706), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '房间号: ${widget.roomCode} (点击复制)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else if (widget.hostContext.roomOrTableName != null)
              Text(
                widget.hostContext.roomOrTableName!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
              GameAudioService().isBgmEnabled ? Icons.music_note : Icons.music_off,
              color: GameAudioService().isBgmEnabled ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
            ),
            tooltip: '背景音乐开关',
            onPressed: () {
              setState(() {
                GameAudioService().toggleBgm();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: '重新开局',
            onPressed: () => _engine.startNewMatch(players: widget.players),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部玩家状态与牛头惩罚榜
            _buildPlayerScoreBar(state),

            // 中间游戏牌阵对决主桌面
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    // 回合提示与当前状态指示条
                    _buildRoundStatusBar(state, isMyTurnToChooseRow),
                    const SizedBox(height: 6),

                    // 4 移行牌桌面
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: state.rows.map((row) {
                            return Take6RowWidget(
                              row: row,
                              isSelectableToTake: isMyTurnToChooseRow,
                              onSelectRow: () => _onSelectRowToTake(row.rowIndex),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 本回合各位玩家翻开的牌
                    _buildRevealedCardsRow(state),
                    const SizedBox(height: 6),

                    // 底部裁判播报事件滚动日志 (紧凑高度)
                    _buildEventLogBox(state),
                  ],
                ),
              ),
            ),

            // 底部玩家手牌操作托盘
            if (state.phase != Take6Phase.gameOver)
              Take6HandWidget(
                handCards: myHand,
                selectedCard: _selectedCard,
                canPlay: state.phase == Take6Phase.selectingCard && mySelectedCard == null,
                onCardSelected: (card) {
                  setState(() {
                    _selectedCard = card;
                  });
                },
                onConfirmPlay: _onConfirmPlay,
              )
            else
              _buildGameOverResultBanner(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScoreBar(Take6State state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: state.players.map((p) {
          final isMe = p.id == widget.localPlayerId;
          final penalty = state.penaltyScores[p.id] ?? 0;
          final isReady = state.selectedCards[p.id] != null;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFCCFBF1).withOpacity(0.5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: isMe ? Border.all(color: const Color(0xFF0D9488), width: 1.2) : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: p.isAi ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                  child: Text(
                    p.isAi ? '🤖' : (p.name.isNotEmpty ? p.name[0] : '我'),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: isMe ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                        fontSize: 11,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '🐮 $penalty 头 ${state.phase == Take6Phase.selectingCard ? (isReady ? '✓' : '...') : ''}',
                      style: TextStyle(
                        color: penalty > 15 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoundStatusBar(Take6State state, bool isMyTurnToChooseRow) {
    String statusText;
    Color statusColor = const Color(0xFF0D9488);
    Color statusBg = const Color(0xFFF0FDFA);

    if (state.phase == Take6Phase.selectingCard) {
      final mySelected = state.selectedCards[widget.localPlayerId] != null;
      statusText = mySelected ? '已选定手牌，等待其他玩家出牌...' : '第 ${state.currentTurn}/10 回合 · 请选择一张手牌';
    } else if (state.phase == Take6Phase.revealing) {
      statusText = '全部玩家已选定，亮牌入列！';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
    } else if (state.phase == Take6Phase.awaitingRowChoice) {
      statusText = isMyTurnToChooseRow ? '⚠️ 您的牌太小！请在上方选择收走任意一行' : '等待玩家挑选收走的行牌...';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    } else if (state.phase == Take6Phase.resolving) {
      statusText = '正在按牌面从小到大排序入行...';
    } else {
      statusText = '游戏结束！';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRevealedCardsRow(Take6State state) {
    if (state.phase == Take6Phase.selectingCard) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: state.players.map((p) {
          final card = state.selectedCards[p.id];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Take6CardWidget(
                  card: card,
                  width: 38,
                  height: 52,
                ),
                const SizedBox(height: 2),
                Text(
                  p.name,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventLogBox(Take6State state) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.builder(
        controller: _logScrollCtrl,
        itemCount: state.eventLogs.length,
        itemBuilder: (context, index) {
          return Text(
            state.eventLogs[index],
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          );
        },
      ),
    );
  }

  Widget _buildGameOverResultBanner(Take6State state) {
    final ranking = List<GamePlayer>.from(state.players)
      ..sort((a, b) => (state.penaltyScores[a.id] ?? 0).compareTo(state.penaltyScores[b.id] ?? 0));
    final winner = ranking.first;
    final isMeWinner = winner.id == widget.localPlayerId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isMeWinner ? '🎉 恭喜您获得最终胜利！' : '🏁 游戏结束',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            '获胜者：${winner.name} (仅累计 🐮x${state.penaltyScores[winner.id]} 头牛)',
            style: const TextStyle(fontSize: 13, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _engine.startNewMatch(players: widget.players),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            ),
            child: const Text('再来一局 🐮', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
