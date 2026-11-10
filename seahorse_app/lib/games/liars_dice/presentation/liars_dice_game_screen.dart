import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/contracts/game_channel.dart';
import '../../core/contracts/game_host_context.dart';
import '../../core/contracts/game_reward_bridge.dart';
import '../../core/models/game_action.dart';
import '../../core/models/game_player.dart';
import '../../core/services/game_audio_service.dart';
import '../adapters/dice_ai_channel.dart';
import '../adapters/dice_local_auditor.dart';
import '../domain/dice_rules_engine.dart';
import '../domain/dice_state.dart';
import 'widgets/bid_dial_widget.dart';
import 'widgets/dice_cup_widget.dart';
import 'widgets/dice_shake_detector.dart';

/// 大话骰 / 骰子街 - 纯整洁架构游戏主界面 (Liar's Dice Presentation Screen)
class LiarsDiceGameScreen extends StatefulWidget {
  final IGameChannel channel;
  final DiceLocalAuditor auditor;
  final IGameRewardBridge rewardBridge;
  final IGameHostContext hostContext;
  final List<GamePlayer> players;
  final String myPlayerId;
  final String? roomCode;

  const LiarsDiceGameScreen({
    Key? key,
    required this.channel,
    required this.auditor,
    required this.rewardBridge,
    required this.hostContext,
    required this.players,
    required this.myPlayerId,
    this.roomCode,
  }) : super(key: key);

  /// 快速构建工厂方法（默认单机/离线 AI 对战）
  static Widget createOffline({
    required List<GamePlayer> players,
    required String myPlayerId,
    required IGameRewardBridge rewardBridge,
    required IGameHostContext hostContext,
    String? roomCode,
  }) {
    final engine = DiceRulesEngine();
    final auditor = DiceLocalAuditor(engine: engine);
    final channel = DiceAiChannel();

    return LiarsDiceGameScreen(
      channel: channel,
      auditor: auditor,
      rewardBridge: rewardBridge,
      hostContext: hostContext,
      players: players,
      myPlayerId: myPlayerId,
      roomCode: roomCode,
    );
  }

  @override
  State<LiarsDiceGameScreen> createState() => _LiarsDiceGameScreenState();
}

class _LiarsDiceGameScreenState extends State<LiarsDiceGameScreen> {
  late DiceRulesEngine _engine;
  late StreamSubscription _channelSub;
  late StreamSubscription _stateSub;
  DiceState? _currentState;
  final ScrollController _logScrollController = ScrollController();
  bool _isRealShakeMode = true;

  @override
  void initState() {
    super.initState();
    _initGame();
    GameAudioService().startBgm();
  }

  void _initGame() {
    _engine = widget.auditor.engine;

    // 订阅领域状态变更
    _stateSub = _engine.stateStream.listen((state) {
      if (mounted) {
        setState(() => _currentState = state);
        widget.channel.broadcastState(state);
        _scrollToBottom();
      }
    });

    // 订阅信道动作流
    _channelSub = widget.channel.actionStream.listen((action) {
      final res = widget.auditor.executeAction(action);
      if (!res.isSuccess && action.playerId == widget.myPlayerId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${res.message}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // 启动首回合
    _engine.startNewRound(players: widget.players);
    _currentState = _engine.state;
    widget.channel.broadcastState(_currentState!);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    GameAudioService().stopBgm();
    _channelSub.cancel();
    _stateSub.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _onPlayerBid(int count, int face, bool isPure) {
    GameAudioService().playSound('bid_ding');
    final action = GameAction(
      actionId: 'ACT-BID-${DateTime.now().millisecondsSinceEpoch}',
      playerId: widget.myPlayerId,
      actionType: 'BID',
      payload: {
        'count': count,
        'face': face,
        'isPure': isPure,
      },
    );
    widget.channel.dispatchAction(action);
  }

  void _onPlayerChallenge() {
    GameAudioService().playSound('challenge_bang');
    final action = GameAction(
      actionId: 'ACT-CHALLENGE-${DateTime.now().millisecondsSinceEpoch}',
      playerId: widget.myPlayerId,
      actionType: 'CHALLENGE',
      payload: {},
    );
    widget.channel.dispatchAction(action);
  }

  void _restartNextRound() {
    GameAudioService().playSound('dice_shake');
    _engine.startNewRound(
      players: widget.players,
      starterIndex: (_currentState?.currentTurnIndex ?? 0) + 1,
      initialChips: _currentState?.chipsScore,
    );
  }

  void _onPhysicalShakeFinished() {
    _restartNextRound();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎲 物理摇晃感应成功！全场骰盅已重新摇好扣紧！'),
        backgroundColor: Colors.amber,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyRoomCode() {
    if (widget.roomCode == null) return;
    final inviteText = '【海马聚会桌游】大话骰/骰子街开局啦！\n👉 房间号：${widget.roomCode}\n快打开海马 App 加入对局！';
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
  Widget build(BuildContext context) {
    final state = _currentState;
    if (state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final isMyTurn = state.phase == DicePhase.bidding && state.currentPlayer.id == widget.myPlayerId;
    final isRevealed = state.phase == DicePhase.challenged || state.phase == DicePhase.roundOver;
    final opponents = state.players.where((p) => p.id != widget.myPlayerId).toList();
    final myCup = state.playerCups[widget.myPlayerId];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 护眼柔和浅灰底色
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          tooltip: '返回大厅',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              '🎲 骰子街 / 大话骰',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
            else
              Text(
                '${widget.hostContext.appName} · ${widget.hostContext.roomOrTableNumber ?? '离线包厢'}',
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
              _isRealShakeMode ? Icons.vibration : Icons.touch_app,
              color: _isRealShakeMode ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
            ),
            tooltip: _isRealShakeMode ? '真实物理摇晃模式 (已开启)' : '手动摇骰模式 (点击切换为真实摇晃)',
            onPressed: () {
              setState(() {
                _isRealShakeMode = !_isRealShakeMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isRealShakeMode ? '📱 已开启【真实物理摇晃模式】：用力摇晃手机即可摇骰！' : '👆 已切换为【手动按键摇骰模式】'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
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
            icon: const Icon(Icons.refresh, color: Color(0xFF475569)),
            tooltip: '重新摇骰开新局',
            onPressed: _restartNextRound,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF64748B)),
            onPressed: () => _showRulesDialog(context),
          ),
        ],
      ),
      body: DiceShakeDetector(
        isEnabled: _isRealShakeMode,
        onShakeFinished: _onPhysicalShakeFinished,
        child: Column(
        children: [
          // 顶部全场筹码仪表板
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: state.players.map((p) {
                final chips = state.chipsScore[p.id] ?? 100;
                final isTurn = state.currentPlayer.id == p.id;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTurn ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: isTurn ? Border.all(color: const Color(0xFFD97706), width: 1.5) : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: p.isAi ? const Color(0xFF94A3B8) : const Color(0xFFEA580C),
                        child: Text(
                          p.name.substring(0, 1),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.name}: ',
                        style: TextStyle(
                          color: isTurn ? const Color(0xFF92400E) : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '🪙 $chips',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // 对手骰盅展示区
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: opponents.map((opp) {
                final cup = state.playerCups[opp.id]!;
                return DiceCupWidget(
                  playerName: opp.name,
                  cup: cup,
                  isCurrentTurn: state.currentPlayer.id == opp.id,
                  isSelf: false,
                  isRevealedAll: isRevealed,
                  highlightFace: state.currentBid?.face,
                  isWild1Active: state.isWild1Active && !(state.currentBid?.isPure ?? false),
                );
              }).toList(),
            ),
          ),

          // 中间：实时出价战报与动态播报
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: state.eventLogs.length,
                itemBuilder: (ctx, idx) {
                  final log = state.eventLogs[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: log.contains('💥')
                            ? const Color(0xFFDC2626)
                            : log.contains('🗣️')
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: log.contains('💥') || log.contains('🗣️') ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 揭晓裁决结果提示横幅 (若已开盅)
          if (isRevealed && state.lastResult != null)
            _buildResultBanner(state.lastResult!),

          // 自己专属的骰盅
          if (myCup != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DiceCupWidget(
                playerName: '我的骰盅',
                cup: myCup,
                isCurrentTurn: isMyTurn,
                isSelf: true,
                isRevealedAll: isRevealed,
                highlightFace: state.currentBid?.face,
                isWild1Active: state.isWild1Active && !(state.currentBid?.isPure ?? false),
              ),
            ),

          // 底部叫点控制面板
          if (!isRevealed)
            BidDialWidget(
              currentBid: state.currentBid,
              totalPlayers: state.players.length,
              isWild1Active: state.isWild1Active,
              isMyTurn: isMyTurn,
              onBid: _onPlayerBid,
              onChallenge: _onPlayerChallenge,
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _restartNextRound,
                icon: const Icon(Icons.play_arrow),
                label: const Text('准备好了，摇骰开下一局！', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildResultBanner(DiceChallengeResult res) {
    final isSuccess = res.isChallengerWon;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.verified : Icons.error,
                color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '全场实际共 ${res.actualMatchCount} 个 ${res.challengedBid.face}！',
                style: TextStyle(
                  color: isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '【${res.challengerName}】抓【${res.challengedBid.bidderName}】叫的 ${res.challengedBid.count} 个：'
            '${isSuccess ? "抓吹牛成功！" : "抓错了！"} '
            '【${res.loserName}】受罚！',
            style: TextStyle(
              color: isSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '各家点数: ${res.details}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎲 大话骰 / 骰子街 规则', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. 【起手】：每人 5 粒骰子，扣好骰盅。按住自己的骰盅可以偷瞄点数。\n'
                '2. 【叫点】：顺时针叫点（如“4个5”）。后续玩家必须“加数量”（如“5个5”）或“加点数”（如“4个6”）。\n'
                '3. 【通配与斋】：1 点默认为“飞/通配符”，可当做任意点数！一旦有人叫了 1 点或主动喊“斋”，1 点立刻失去通配功能，只能当 1 点。\n'
                '4. 【开/劈】：如果你认为上一家在吹牛，实际没有那么多颗骰子，直接按“开/劈”！全场亮盅核对：\n'
                '   - 实际数量 >= 叫点数：叫点者赢，开盅者受罚输 10 筹码。\n'
                '   - 实际数量 < 叫点数：开盅者赢，叫点者吹牛被抓输 10 筹码。',
                style: TextStyle(color: Color(0xFF475569), height: 1.5, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }
}
