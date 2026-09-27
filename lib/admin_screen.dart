import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'main.dart';
import 'dart:math' as math;

// ==========================================
// 管理者用画面 (適性診断)
// ==========================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  static const Color iconColor = Color(0xFF28004F);
  static const Color gradientBaseColor = Color(0xFFDFBFFF);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<_PersonalDataTabState> _personalDataTabKey =
      GlobalKey<_PersonalDataTabState>();
  final GlobalKey<_AnalysisTabState> _analysisTabKey =
      GlobalKey<_AnalysisTabState>();
  final GlobalKey<_AppEditTabState> _appEditTabKey =
      GlobalKey<_AppEditTabState>();

  void _handleBack() {
    if (_analysisTabKey.currentState?.handleBack() == true) {
      return;
    }
    if (_personalDataTabKey.currentState?.handleBack() == true) {
      return;
    }
    if (_appEditTabKey.currentState?.handleBack() == true) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(
          appName: '適性診断',
          originalHome: HomeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AdminHomeScreen.gradientBaseColor],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AdminHomeScreen.iconColor),
                tooltip: '戻る',
                onPressed: _handleBack,
              ),
              title: Text(
                '適性診断',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AdminHomeScreen.iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              bottom: TabBar(
                labelColor: AdminHomeScreen.iconColor,
                unselectedLabelColor: Colors.black54,
                indicatorColor: AdminHomeScreen.iconColor,
                labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.1),
                unselectedLabelStyle: TextStyle(fontSize: 11, height: 1.1),
                tabs: [
                  Tab(icon: Icon(Icons.people_alt_outlined), child: Text('個人データ\n一覧', textAlign: TextAlign.center)),
                  Tab(icon: Icon(Icons.analytics_outlined), child: Text('分析\n職員用メモ', textAlign: TextAlign.center)),
                  Tab(icon: Icon(Icons.app_settings_alt_outlined), child: Text('機能編集\n管理', textAlign: TextAlign.center)),
                  Tab(icon: Icon(Icons.import_export_outlined), child: Text('外部出力\n連携', textAlign: TextAlign.center)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PersonalDataTab(key: _personalDataTabKey, iconColor: AdminHomeScreen.iconColor),
                _AnalysisTab(key: _analysisTabKey, iconColor: AdminHomeScreen.iconColor),
                _AppEditTab(key: _appEditTabKey, iconColor: AdminHomeScreen.iconColor),
                const _ExportTab(iconColor: AdminHomeScreen.iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSubHeader extends StatelessWidget {
  final Color iconColor;
  const _AdminSubHeader({required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: iconColor,
              side: BorderSide(color: iconColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('設定'),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            onSelected: (String value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: iconColor,
                  content: Text('$value が選択されました', style: const TextStyle(color: Colors.white)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: '使い方１', child: Text('使い方１', style: TextStyle(color: iconColor))),
              PopupMenuItem<String>(value: '使い方２', child: Text('使い方２', style: TextStyle(color: iconColor))),
              PopupMenuItem<String>(value: '使い方３', child: Text('使い方３', style: TextStyle(color: iconColor))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: iconColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 18, color: iconColor),
                  const SizedBox(width: 6),
                  Text('使い方', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: iconColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: iconColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Skill User
class SkillUser {
  final String name;
  final int earnedSp;
  final List<double> radarValues; // Creativity, Focus, Cooperation, Technical, Physical
  final List<double> spBoostValues; // SP add-on boosts
  final List<String> historyDates;
  final List<String> recommendedCareers;
  final String strengthType;

  SkillUser({
    required this.name,
    required this.earnedSp,
    required this.radarValues,
    required this.spBoostValues,
    required this.historyDates,
    required this.recommendedCareers,
    required this.strengthType,
  });
}

// ==========================================
// 1. 個人データ一覧 タブ
// ==========================================
class _PersonalDataTab extends StatefulWidget {
  final Color iconColor;
  const _PersonalDataTab({super.key, required this.iconColor});

  @override
  State<_PersonalDataTab> createState() => _PersonalDataTabState();
}

class _PersonalDataTabState extends State<_PersonalDataTab> {
  SkillUser? _selectedUser;

  final List<SkillUser> _users = [
    SkillUser(
      name: '田中 太郎',
      earnedSp: 1200,
      radarValues: [85, 70, 80, 75, 60, 80],
      spBoostValues: [10, 15, 8, 12, 10, 15],
      historyDates: ['2026/08/01', '2026/07/15', '2026/06/10'],
      recommendedCareers: ['Webデザイナー', 'グラフィックコーダー', 'イラストレーター'],
      strengthType: 'クリエイティブ・視覚表現型 (デザイン等に高い意欲)',
    ),
    SkillUser(
      name: '佐藤 花子',
      earnedSp: 850,
      radarValues: [60, 90, 75, 80, 50, 70],
      spBoostValues: [8, 12, 10, 15, 8, 10],
      historyDates: ['2026/07/28', '2026/07/02'],
      recommendedCareers: ['データ入力オペレーター', 'DTMサウンドエディター'],
      strengthType: '集中持続・分析検証型 (ミスの少ない事務・サウンド編集向き)',
    ),
    SkillUser(
      name: '鈴木 一郎',
      earnedSp: 950,
      radarValues: [50, 65, 85, 60, 90, 65],
      spBoostValues: [12, 8, 15, 10, 12, 8],
      historyDates: ['2026/08/02', '2026/07/20'],
      recommendedCareers: ['物流梱包・ピッキング作業員', '施設管理サポート'],
      strengthType: '協調連携・身体実務型 (周囲とのバトン連携や実務作業で活躍)',
    ),
  ];

  bool handleBack() {
    if (_selectedUser != null) {
      setState(() {
        _selectedUser = null;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _selectedUser != null
        ? _buildUserDetailMode(_selectedUser!)
        : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AdminSubHeader(iconColor: widget.iconColor),
        Row(
          children: [
            Icon(Icons.people, color: widget.iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '登録利用者一覧 (回答履歴)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.iconColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._users.map((u) {
          return Card(
            color: Colors.white.withOpacity(0.9),
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: widget.iconColor.withOpacity(0.1),
                child: Icon(Icons.badge, color: widget.iconColor),
              ),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('累計獲得SP: ${u.earnedSp} SP (作業手順より連携)'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                setState(() {
                  _selectedUser = u;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // 個人メニュー読み取り (レーダーチャート表示、回答、SP反映)
  Widget _buildUserDetailMode(SkillUser user) {
    final appState = Provider.of<AppState>(context);
    final categories = appState.currentQuestionSet?.categories ?? ['画力', '創造性', '構成力', '表現力', '集中力', '効率性'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: widget.iconColor),
              onPressed: () => setState(() => _selectedUser = null),
            ),
            Text('${user.name} - 適性診断個人メニュー', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.iconColor)),
          ],
        ),
        const SizedBox(height: 12),

        // レーダーチャート & SP表示
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('■ 適正特性チャート', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                // 凡例
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('自己評価', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('SP上乗せブースト', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CustomPaint(
                    painter: _SimulatedRadarPainter(
                      values: user.radarValues,
                      spBoosts: user.spBoostValues,
                      baseColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(categories.length, (index) {
                    final label = categories[index];
                    final baseVal = index < user.radarValues.length ? user.radarValues[index] : 0.0;
                    final boostVal = index < user.spBoostValues.length ? user.spBoostValues[index] : 0.0;
                    return _buildLabel(label, baseVal.round(), boostVal.round());
                  }),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('他アプリ（作業手順等）からの連携SP: ', style: TextStyle(fontSize: 12)),
                    Text('${user.earnedSp} SP', style: TextStyle(fontWeight: FontWeight.bold, color: widget.iconColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 回答履歴
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('■ 診断の回答受検履歴', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...user.historyDates.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('受検日: $d', style: const TextStyle(fontSize: 12)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: widget.iconColor, foregroundColor: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$d 実施分の回答詳細シートを開きます。')),
                              );
                            },
                            child: const Text('回答ログを見る', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String name, int score, int boostScore) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('$score', style: const TextStyle(fontSize: 11, color: Colors.black87)),
        Text(
          '+$boostScore',
          style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SimulatedRadarPainter extends CustomPainter {
  final List<double> values;
  final List<double> spBoosts;
  final Color baseColor;
  final Color boostColor = Colors.orange;

  _SimulatedRadarPainter({
    required this.values,
    required this.spBoosts,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    final paintLine = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintFillBase = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final paintBorderBase = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintFillBoost = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final paintBorderBoost = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final count = values.length;
    if (count == 0) return;

    // Draw background polygon grids (3 levels)
    for (double r = 0.3; r <= 1.0; r += 0.35) {
      final currentRadius = radius * r;
      final pathGrid = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * 2 * math.pi / count) - math.pi / 2;
        final x = centerX + currentRadius * math.cos(angle);
        final y = centerY + currentRadius * math.sin(angle);
        if (i == 0) {
          pathGrid.moveTo(x, y);
        } else {
          pathGrid.lineTo(x, y);
        }
      }
      pathGrid.close();
      canvas.drawPath(pathGrid, paintLine);
    }

    // 1. Draw SP Boosted Values Polygon (Base + Boost)
    final pathBoost = Path();
    for (int i = 0; i < count; i++) {
      final boostVal = i < spBoosts.length ? spBoosts[i] : 0.0;
      final totalVal = values[i] + boostVal;
      final valPercentage = totalVal / 100.0;
      final currentRadius = radius * (valPercentage > 1.0 ? 1.0 : valPercentage);
      final angle = (i * 2 * math.pi / count) - math.pi / 2;
      final x = centerX + currentRadius * math.cos(angle);
      final y = centerY + currentRadius * math.sin(angle);
      if (i == 0) {
        pathBoost.moveTo(x, y);
      } else {
        pathBoost.lineTo(x, y);
      }
    }
    pathBoost.close();
    canvas.drawPath(pathBoost, paintFillBoost);
    canvas.drawPath(pathBoost, paintBorderBoost);

    // 2. Draw Base Values Polygon
    final pathBase = Path();
    for (int i = 0; i < count; i++) {
      final valPercentage = values[i] / 100.0;
      final currentRadius = radius * valPercentage;
      final angle = (i * 2 * math.pi / count) - math.pi / 2;
      final x = centerX + currentRadius * math.cos(angle);
      final y = centerY + currentRadius * math.sin(angle);
      if (i == 0) {
        pathBase.moveTo(x, y);
      } else {
        pathBase.lineTo(x, y);
      }
    }
    pathBase.close();
    canvas.drawPath(pathBase, paintFillBase);
    canvas.drawPath(pathBase, paintBorderBase);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 2. 分析・職員用メモ タブ
// ==========================================
class _AnalysisTab extends StatefulWidget {
  final Color iconColor;
  const _AnalysisTab({super.key, required this.iconColor});

  @override
  State<_AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<_AnalysisTab> {
  bool _showAdminMemos = false;

  bool handleBack() {
    if (_showAdminMemos) {
      setState(() => _showAdminMemos = false);
      return true;
    }
    return false;
  }

  final TextEditingController _notesController = TextEditingController(
    text: '田中さんはクリエイティブ面が特筆して高い。今後はPCでのイラストデザイン作業を中心に配属を組む。',
  );

  @override
  Widget build(BuildContext context) {
    if (_showAdminMemos) {
      return AdminSkillMemosScreen(
        iconColor: widget.iconColor,
        onBack: () => setState(() => _showAdminMemos = false),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),
        const SizedBox(height: 12),

        // 管理者用メモ（最優先・データ分析の要）
        Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: widget.iconColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.iconColor.withValues(alpha: 0.08),
                  Colors.white,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.analytics_outlined, color: widget.iconColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '管理者用メモ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: widget.iconColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '分析の要',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI分析・個別支援データ蓄積と記録',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.iconColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => setState(() => _showAdminMemos = true),
                  icon: const Icon(Icons.note_alt_outlined, size: 20),
                  label: const Text(
                    '適性メモ表示',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 「案内ひろば」AI分析のヒント（管理者用メモの真下に配置）
        _buildSupportHubPromptCard(
          context: context,
          iconColor: widget.iconColor,
          crossAppPrompts: [
            '適性診断で出た強みが、実際の作業手順（work_guide）の成果にどう現れているか検証して',
            '適性診断と過去の全記録（勤怠・体調・作業）を総合して、就労に向けた推薦文を作成して',
            'チーム全体の適性バランスを見て、最適な作業ペア・グループ配置を提案して',
          ],
          singleAppPrompts: [
            '診断結果から見出された「上位の強み・適性（正確性、集中力、協調性等）」をまとめて',
            '本人の特性に最もマッチする作業分野（検品、PC、軽作業等）のランキングを出して',
            '班・グループ全体（イラスト、DTM、モデリング等）の平均適性傾向やSP構成バランスを分析して',
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSupportHubPromptCard({
    required BuildContext context,
    required Color iconColor,
    required List<String> crossAppPrompts,
    required List<String> singleAppPrompts,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: iconColor.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '「案内ひろば」AI分析のヒント',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 11, color: Colors.blue.shade800),
                            const SizedBox(width: 3),
                            Text(
                              'Gemini連携',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'マスターアプリ「案内ひろば」のAIにこう聞いてみよう！（タップでコピー）',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.link, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  '他のデータと掛け合わせて分析',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...crossAppPrompts.map((prompt) => _buildPromptItem(context, prompt, iconColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.search, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  'このアプリのデータを深掘り分析',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...singleAppPrompts.map((prompt) => _buildPromptItem(context, prompt, iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptItem(BuildContext context, String prompt, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Clipboard.setData(ClipboardData(text: prompt));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '質問文をコピーしました！「案内ひろば」で貼り付けて使えます',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E293B),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Icon(Icons.chat_bubble_outline, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. 機能編集・管理 タブ
// ==========================================
class _AppEditTab extends StatefulWidget {
  final Color iconColor;
  const _AppEditTab({super.key, required this.iconColor});

  @override
  State<_AppEditTab> createState() => _AppEditTabState();
}

class _AppEditTabState extends State<_AppEditTab> {
  bool _isEditing = false;

  final List<String> _jobMappings = [
    'イラスト制作 -> クリエイティブ特性が影響',
    'ピッキング作業 -> 集中持続・身体実務が影響',
    'DTM音声編集 -> 集中力特性が影響',
  ];

  bool handleBack() {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _isEditing
        ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: widget.iconColor),
                      onPressed: () => setState(() => _isEditing = false),
                    ),
                    Text('設問の編集', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.iconColor)),
                  ],
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 600,
                  child: QuestionEditScreen(isEmbedded: true),
                ),
              ],
            )
          : _buildDefaultEditMode(context);
  }

  Widget _buildDefaultEditMode(BuildContext context) {

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),

        // 設問、マスター管理
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text('適性診断設問・マスター編集', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('設問の編集', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 職種、作業セットの管理
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work_outline, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text('推奨職種・作業セットマッピングの管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                ..._jobMappings.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $m', style: const TextStyle(fontSize: 12)),
                    )),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: widget.iconColor, side: BorderSide(color: widget.iconColor)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('マッピング詳細設定を開きます。')),
                          );
                        },
                        child: const Text('マッピング基準の編集'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 4. 外部出力・連携 タブ
// ==========================================
class _ExportTab extends StatefulWidget {
  final Color iconColor;
  const _ExportTab({required this.iconColor});

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  String _selectedUser = '田中 太郎';
  bool _isAutoImportSpActive = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),

        // ポートフォリオ作成
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_shared_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text('利用者用アピールポートフォリオの作成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('本人の適性診断レーダーチャートと、日報で作成したできたことログを１つに統合したポートフォリオシートを自動作成します。', style: TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('対象者: ', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedUser,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: widget.iconColor, fontWeight: FontWeight.bold),
                      items: <String>['田中 太郎', '佐藤 花子', '鈴木 一郎'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedUser = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: widget.iconColor, foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('自己アピールポートフォリオ(PDF)を出力'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: widget.iconColor,
                              content: Text('$_selectedUser のポートフォリオシート(PDF)を出力しました。'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 他アプリデータ連携
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_alt, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text('他アプリデータ連携設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('作業手順(work_guide)や日報(daily_report)から獲得SPを自動で連携・集計する', style: TextStyle(fontSize: 13)),
                  activeColor: widget.iconColor,
                  value: _isAutoImportSpActive,
                  onChanged: (val) => setState(() => _isAutoImportSpActive = val),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 適性診断：管理者用メモ画面
// ==========================================

class SkillMemo {
  final String id;
  final String userName;
  final String aptitudeAnalysis;
  final String recommendedTask;
  final String teachingMethod;
  final String notes;
  final DateTime recordedAt;

  SkillMemo({
    required this.id,
    required this.userName,
    required this.aptitudeAnalysis,
    required this.recommendedTask,
    required this.teachingMethod,
    required this.notes,
    required this.recordedAt,
  });
}

class AdminSkillMemosScreen extends StatefulWidget {
  final Color iconColor;
  final VoidCallback onBack;

  const AdminSkillMemosScreen({
    super.key,
    required this.iconColor,
    required this.onBack,
  });

  @override
  State<AdminSkillMemosScreen> createState() => _AdminSkillMemosScreenState();
}

class _AdminSkillMemosScreenState extends State<AdminSkillMemosScreen> {
  final List<String> _users = ['田中 太郎', '佐藤 花子', '鈴木 一郎'];
  late String _selectedUser;
  String _filterUser = '全員';

  final List<String> _aptitudeOptions = [
    '創意工夫・柔軟性',
    '集中力・持続力',
    '単純作業・正確性',
    'コミュニケーション力',
    '丁寧さ・慎重さ',
    'スピード・効率',
  ];
  late String _selectedAptitude;

  final List<String> _recommendedTaskOptions = [
    '創作・デザイン',
    'PC入力・事務',
    '軽作業・仕分け',
    '検品・梱包',
    '清掃・環境整備',
    '接客・受付',
  ];
  late String _selectedRecommendedTask;

  final List<String> _teachingMethodOptions = [
    '自由度を高める',
    '視覚的な図解・手順書',
    '口頭での丁寧な説明',
    '一緒に見本を示す',
    'スモールステップで段階指導',
  ];
  late String _selectedTeachingMethod;

  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  late List<SkillMemo> _memos;

  @override
  void initState() {
    super.initState();
    _selectedUser = _users.first;
    _selectedAptitude = _aptitudeOptions.first;
    _selectedRecommendedTask = _recommendedTaskOptions.first;
    _selectedTeachingMethod = _teachingMethodOptions.first;

    _memos = [
      SkillMemo(
        id: '1',
        userName: '田中 太郎',
        aptitudeAnalysis: '創意工夫・柔軟性',
        recommendedTask: '創作・デザイン',
        teachingMethod: '自由度を高める',
        notes: '色彩感覚とレイアウト構成力が高く、イラスト・バナー制作において独自のセンスを発揮している。指導時は大枠のテーマのみ提示し、本人の自主性を尊重すると良い成果が出る。',
        recordedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SkillMemo(
        id: '2',
        userName: '佐藤 花子',
        aptitudeAnalysis: '集中力・持続力',
        recommendedTask: 'PC入力・事務',
        teachingMethod: '視覚的な図解・手順書',
        notes: 'データ入力やチェック作業の正確性が非常に高い。文字主体の指示よりもチェックリスト形式の手順書を渡すと、迷わずスムーズに作業を完遂できる。',
        recordedAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      SkillMemo(
        id: '3',
        userName: '鈴木 一郎',
        aptitudeAnalysis: '単純作業・正確性',
        recommendedTask: '検品・梱包',
        teachingMethod: 'スモールステップで段階指導',
        notes: '手先が器用で丁寧な仕上がり。複雑な工程は一度に説明せず、1工程ずつ習得を確認しながら進めると定着が早い。',
        recordedAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
    ];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveMemo() {
    final newDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newMemo = SkillMemo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: _selectedUser,
      aptitudeAnalysis: _selectedAptitude,
      recommendedTask: _selectedRecommendedTask,
      teachingMethod: _selectedTeachingMethod,
      notes: _notesController.text.trim(),
      recordedAt: newDateTime,
    );

    setState(() {
      _memos.insert(0, newMemo);
      _notesController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: widget.iconColor,
        content: Text('$_selectedUser さんの適性メモを保存しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteMemo(String id) {
    setState(() {
      _memos.removeWhere((m) => m.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: widget.iconColor,
        content: const Text('メモを削除しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMemos = _filterUser == '全員'
        ? _memos
        : _memos.where((m) => m.userName == _filterUser).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 戻るヘッダー
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: widget.iconColor, size: 20),
              onPressed: widget.onBack,
              tooltip: '戻る',
            ),
            Text(
              '【管理】適性メモ (閲覧/代理記録)',
              style: TextStyle(
                color: widget.iconColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 新規メモ作成カード
        Card(
          color: Colors.white.withOpacity(0.95),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '新規適性メモ作成',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 1. メモ対象者
                const Text(
                  'メモ対象者',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedUser,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _users.map((user) => DropdownMenuItem(value: user, child: Text(user))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUser = val);
                  },
                ),
                const SizedBox(height: 14),

                // 2. 適性・強み分析
                const Text(
                  '適性・強み分析',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedAptitude,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _aptitudeOptions.map((apt) => DropdownMenuItem(value: apt, child: Text(apt))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAptitude = val);
                  },
                ),
                const SizedBox(height: 14),

                // 3. おすすめの作業
                const Text(
                  'おすすめの作業',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _recommendedTaskOptions.map((task) {
                    final isSelected = _selectedRecommendedTask == task;
                    return ChoiceChip(
                      label: Text(task),
                      selected: isSelected,
                      selectedColor: widget.iconColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? widget.iconColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRecommendedTask = task);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 4. マッチする指導方法
                const Text(
                  'マッチする指導方法',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _teachingMethodOptions.map((method) {
                    final isSelected = _selectedTeachingMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      selectedColor: widget.iconColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? widget.iconColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedTeachingMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 5. 詳細メモ
                const Text(
                  'メモ・特記事項',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '強みや配慮すべき指導法などの詳細を入力...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                // 6. 記録日時
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveMemo,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('メモを保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 過去のメモ一覧ヘッダー & フィルター
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: widget.iconColor),
                const SizedBox(width: 6),
                const Text(
                  '過去の適性メモ一覧',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButton<String>(
                value: _filterUser,
                underline: const SizedBox(),
                isDense: true,
                items: ['全員', ..._users].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _filterUser = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // メモ一覧
        if (filteredMemos.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('記録されたメモはありません', style: TextStyle(color: Colors.grey)),
          )
        else
          ...filteredMemos.map((memo) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Colors.white.withOpacity(0.95),
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.iconColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                memo.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: widget.iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Text(
                                memo.aptitudeAnalysis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () => _deleteMemo(memo.id),
                          tooltip: '削除',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'おすすめ: ${memo.recommendedTask}',
                            style: TextStyle(fontSize: 11, color: Colors.indigo.shade900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '指導: ${memo.teachingMethod}',
                            style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade900),
                          ),
                        ),
                      ],
                    ),
                    if (memo.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        memo.notes,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(memo.recordedAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }
}

