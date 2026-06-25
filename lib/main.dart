import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ==========================================
// 1. Main Entry Point / アプリの開始地点
// ==========================================

// アプリケーションが起動したときに最初に実行される関数です。
void main() {
  runApp(
    // アプリ全体で「AppState（状態）」を共有できるようにします。
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

// アプリの土台となるウィジェット（構成要素）です。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // コンテキストを通してアプリ全体の状態（AppState）を取得します。
    final appState = Provider.of<AppState>(context, listen: false);

    return MaterialApp(
      title: '適性診断',
      // ナビゲーターキーを登録。これで画面遷移先でも通知（SnackBar）を出しやすくします。
      navigatorKey: appState.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // アプリ全体のフォントに「Noto Sans JP」を使用。
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      // 起動時に表示される最初の画面を設定します。
      initialRoute: '/login',
      routes: {
        '/login':
            (context) => const LoginScreen(
              appName: '適性診断',
              originalHome: HomeScreen(),
            ),
        '/': (context) => const HomeScreen(),
        '/question': (context) => const QuestionScreen(),
        '/result': (context) => const ResultScreen(),
        '/history': (context) => const HistoryScreen(),
        // /history_detail は引数（record）が必要なため、Navigator.pushで直接呼び出します
        '/question_edit': (context) => const QuestionEditScreen(),
      },
    );
  }
}

// ==========================================
// 2. Models / データモデル（情報の設計図）
// ==========================================

// 「質問」ひとつひとつの情報を入れる箱です。
class Question {
  final String id; // 質問を区別するための番号
  final String text; // 質問文そのもの
  final String category; // カテゴリー（技術力、協調性など）
  final int dayIndex; // 何日目の質問か (0〜4)

  Question({
    required this.id,
    required this.text,
    required this.category,
    required this.dayIndex,
  });
}

// 「質問セット」複数の質問をまとめた、職種ごとのテンプレートです。
class QuestionSet {
  final String id; // セットのID
  final String title; // セットの名前（例：動画編集）
  final List<Question> questions; // このセットに含まれる全質問のリスト
  final List<String> categories; // カテゴリー（レーダーチャートの軸名）

  QuestionSet({
    required this.id,
    required this.title,
    required this.questions,
    required this.categories,
  });
}

// 「1日分の記録」その日に答えた内容を記録します。
class DailyRecord {
  final int dayIndex; // 何日目の記録か
  final DateTime date; // 記録した日付
  final Map<String, int> answers; // 質問IDとスコアのセット
  final String memo; // その日の感想・メモ

  DailyRecord({
    required this.dayIndex,
    required this.date,
    required this.answers,
    this.memo = '',
  });

  // データを保存形式（JSON）に変換するための準備です。
  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'date': date.toIso8601String(),
      'answers': answers,
      'memo': memo,
    };
  }

  // 保存形式（JSON）からデータを読み込むための準備です。
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      dayIndex: json['dayIndex'],
      date: DateTime.parse(json['date']),
      answers: Map<String, int>.from(json['answers']),
      memo: json['memo'] ?? '',
    );
  }
}

// 「1週間分の記録」過去の履歴として残すためのデータです。
class WeeklyRecord {
  final String id; // 履歴ごとのID
  final DateTime startDate; // この週の開始日
  final List<DailyRecord> dailyRecords; // 5日間それぞれの記録
  final String title; // ジャンル名（職種）

  WeeklyRecord({
    required this.id,
    required this.startDate,
    required this.dailyRecords,
    required this.title,
  });

  // 履歴全体を保存形式（JSON）に変換します。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'dailyRecords': dailyRecords.map((r) => r.toJson()).toList(),
      'title': title,
    };
  }

  // 保存されている形式から元のデータに戻します。
  factory WeeklyRecord.fromJson(Map<String, dynamic> json) {
    return WeeklyRecord(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      dailyRecords:
          (json['dailyRecords'] as List)
              .map((r) => DailyRecord.fromJson(r))
              .toList(),
      title: json['title'] ?? '不明',
    );
  }
}

// ==========================================
// Data / データ
// ==========================================

// ダミーデータを提供するクラス
class DummyData {
  // 基本のカテゴリーリスト
  static final List<String> categories = [
    '技術力',
    '集中力',
    '協調性',
    '正確性',
    '創造性',
    '論理性',
  ];

  // 質問セットのダミーデータを生成
  static List<QuestionSet> getQuestionSets() {
    return [
      _createQuestionSet('QS000', 'イラスト', 'イラスト制作', [
        '画力',
        '創造性',
        '構成力',
        '表現力',
        '集中力',
        '効率性',
      ]),
      _createQuestionSet('QS001', '動画編集', '動画編集作業', [
        '技術力',
        '集中力',
        '協調性',
        '正確性',
        '創造性',
        '論理性',
      ]),
      _createQuestionSet('QS002', '事務作業', 'データ入力・書類作成', [
        '正確性',
        '集中力',
        '効率性',
        '理解力',
        '整理力',
        '丁寧さ',
      ]),
      _createQuestionSet('QS003', '清掃作業', '施設内清掃', [
        '丁寧さ',
        '体力',
        '協調性',
        '正確性',
        '効率性',
        '気配り',
      ]),
      _createQuestionSet('QS004', '接客業務', 'カフェ・店舗接客', [
        'コミュニケーション力',
        '笑顔',
        '丁寧さ',
        '正確性',
        '臨機応変',
        '気配り',
      ]),
      _createQuestionSet('QS005', '軽作業', 'ピッキング・梱包', [
        '正確性',
        '集中力',
        '体力',
        '効率性',
        '丁寧さ',
        '持久力',
      ]),
    ];
  }

  // ヘルパーメソッド: 質問セットを作成
  static QuestionSet _createQuestionSet(
    String id,
    String title,
    String context,
    List<String> categories,
  ) {
    List<Question> questions = [];
    for (int day = 0; day < 5; day++) {
      for (int catIndex = 0; catIndex < categories.length; catIndex++) {
        questions.add(
          Question(
            id: '${id}_d${day}_c$catIndex',
            text: _getQuestionText(categories[catIndex], day, context),
            category: categories[catIndex],
            dayIndex: day,
          ),
        );
      }
    }
    return QuestionSet(
      id: id,
      title: title,
      categories: categories,
      questions: questions,
    );
  }

  // ヘルパーメソッド: 質問文を生成
  static String _getQuestionText(String category, int day, String context) {
    if (context == '動画編集' || context == '動画編集作業') {
      return _getVideoEditingQuestion(category, day);
    } else if (context == 'イラスト' || context == 'イラスト制作') {
      return _getIllustrationQuestion(category, day);
    } else if (context == '事務作業' || context == 'データ入力・書類作成') {
      return _getOfficeWorkQuestion(category, day);
    } else if (context == '清掃作業' || context == '施設内清掃') {
      return _getCleaningWorkQuestion(category, day);
    } else if (context == '接客業務' || context == 'カフェ・店舗接客') {
      return _getCustomerServiceQuestion(category, day);
    } else if (context == '軽作業' || context == 'ピッキング・梱包') {
      return _getLightWorkQuestion(category, day);
    }

    // その他のコンテキスト用のデフォルト質問
    switch (category) {
      case '技術力':
        return '$contextにおいて、ツールの操作や手順はスムーズに行えましたか？ (Day ${day + 1})';
      case '集中力':
        return '作業中、他のことに気を取られずに集中を持続できましたか？ (Day ${day + 1})';
      case '協調性':
        return '周囲のメンバーやスタッフと適切なコミュニケーションが取れましたか？ (Day ${day + 1})';
      case '正確性':
        return 'ミスなく、指示通りの手順で作業を完了できましたか？ (Day ${day + 1})';
      case '創造性':
        return 'より良い方法を工夫したり、新しいアイデアを試したりしましたか？ (Day ${day + 1})';
      case '論理性':
        return '作業の優先順位を考え、効率的に進めることができましたか？ (Day ${day + 1})';
      default:
        return '今日の作業は順調でしたか？';
    }
  }

  // イラスト制作専用の質問
  static String _getIllustrationQuestion(String category, int day) {
    final questions = {
      '画力': [
        'デッサンや下書きの線は、思い描いた通りに引けましたか？',
        'キャラクターや物体のバランス（人体構造やパース）は正しく描けましたか？',
        '線画のクリンナップは、抑揚をつけて丁寧に仕上げられましたか？',
        '質感（服のシワ、金属、肌など）を描き分けることができましたか？',
        '細部の書き込み（髪の毛、アクセサリーなど）まで妥協せずに描けましたか？',
      ],
      '創造性': [
        '既存の模倣ではなく、オリジナリティのあるポーズやデザインを考案できましたか？',
        'キャラクターの性格やストーリーが伝わるような工夫を盛り込めましたか？',
        '新しい塗り方や技法、ブラシ設定などを積極的に試してみましたか？',
        'マンネリ化を防ぐため、普段とは違う画風やテイストに挑戦しましたか？',
        '魅力的な世界観を作り出すための背景や小物のアイデアを出せましたか？',
      ],
      '構成力': [
        '画面全体を見たとき、視線誘導を意識したレイアウトが組めましたか？',
        '余白のバランスや断ち切りの位置は適切に設定できましたか？',
        'メインの被写体が最も目立つような構図を選べましたか？',
        'ラフ段階で複数の構図案を出し、最良のものを選択できましたか？',
        '背景とキャラクターの奥行き関係（遠近感）を正しく表現できましたか？',
      ],
      '表現力': [
        '色彩設計（カラー配分）は、テーマやムードに合っていましたか？',
        '光と影（ライティング）を意識し、ドラマチックな演出ができましたか？',
        'キャラクターの表情や仕草から、感情を豊かに表現できましたか？',
        '空気感や温度感が伝わるような塗りやエフェクトを使えましたか？',
        '仕上げの加工（オーバーレイ、ぼかし等）で、絵の魅力を最大限に引き出せましたか？',
      ],
      '集中力': [
        '長時間キャンバスに向かう中で、集中を切らさずに描き続けられましたか？',
        '苦手なパーツや修正作業から逃げずに、粘り強く取り組めましたか？',
        '資料探しの時間に没頭しすぎず、描くこと自体に集中できましたか？',
        'SNSや他の作業に気を取られず、没入状態（ゾーン）に入れましたか？',
        '疲労が溜まってきても、線の勢いや塗りの丁寧さを維持できましたか？',
      ],
      '効率性': [
        'ショートカットキーや左手デバイスを活用して、作画スピードを上げられましたか？',
        'レイヤー構成を整理し、後からの修正がしやすいように管理できましたか？',
        'ラフ、線画、着彩の時間配分を計画通りに進められましたか？',
        '素材やブラシプリセットを活用して、無駄な作業時間を短縮できましたか？',
        '完成のイメージを明確にしてから描き始め、迷走する時間を減らせましたか？',
      ],
    };
    return _getQuestionFromMap(questions, category, day, 'イラスト制作');
  }

  // 動画編集専用の質問（6カテゴリー × 5日間 = 30問）
  static String _getVideoEditingQuestion(String category, int day) {
    final questions = {
      '技術力': [
        'カット編集やトリミングの操作はスムーズに行えましたか？',
        'トランジション（場面転換効果）を適切に挿入できましたか？',
        'テロップや字幕の挿入・編集は問題なくできましたか？',
        '音声の調整（音量・フェードイン/アウト）は適切にできましたか？',
        'エフェクトやカラー補正を使いこなせましたか？',
      ],
      '集中力': [
        'タイムラインを見ながら長時間作業に集中できましたか？',
        '細かいフレーム単位の編集作業に集中を維持できましたか？',
        '複数の素材を扱いながら、注意力を保てましたか？',
        '音声同期やリップシンクの確認作業に集中できましたか？',
        'プレビュー確認と修正を繰り返す作業に粘り強く取り組めましたか？',
      ],
      '協調性': [
        'ディレクターや担当者からの指示を正しく理解できましたか？',
        '修正依頼があった際、柔軟に対応できましたか？',
        '作業の進捗や問題点を適切に報告・共有できましたか？',
        'チームメンバーとファイルや素材の受け渡しがスムーズでしたか？',
        'フィードバックを前向きに受け止め、改善に活かせましたか？',
      ],
      '正確性': [
        '指定されたカット位置や尺（秒数）を正確に守れましたか？',
        'テロップの誤字脱字なく入力できましたか？',
        '書き出し設定（解像度・フォーマット）を正しく設定できましたか？',
        'ファイル名やフォルダの整理を規則通りに行えましたか？',
        '納品前のチェックリストを漏れなく確認できましたか？',
      ],
      '創造性': [
        '映像のリズムやテンポを意識した編集ができましたか？',
        '効果的なBGMや効果音の選択・配置ができましたか？',
        '視聴者の興味を引く演出やアイデアを試せましたか？',
        'オープニングやエンディングに工夫を加えられましたか？',
        '全体の構成やストーリー性を意識した編集ができましたか？',
      ],
      '論理性': [
        '作業の優先順位を考えて効率的に進められましたか？',
        '素材の整理やプロジェクト管理が論理的にできましたか？',
        '編集の手順を計画し、無駄のない作業ができましたか？',
        '問題が発生した際、原因を論理的に特定できましたか？',
        '締め切りから逆算して、時間配分を適切に行えましたか？',
      ],
    };

    return _getQuestionFromMap(questions, category, day, '動画編集');
  }

  // 事務作業専用の質問
  static String _getOfficeWorkQuestion(String category, int day) {
    final questions = {
      '正確性': [
        'データ入力時に数値や文字の入力ミスはありませんでしたか？',
        '書類の誤字脱字やレイアウト崩れを入念にチェックしましたか？',
        'ファイル名や保存場所のルールを正確に守れましたか？',
        '計算式や関数の使用に誤りはありませんでしたか？',
        '最終確認（ダブルチェック）を怠らずに行えましたか？',
      ],
      '集中力': [
        '単調な入力作業でも集中力を切らさずに続けられましたか？',
        '周囲の音や話し声に気を取られず、目の前の作業に没頭できましたか？',
        '長時間デスクワークをする中で、適度な休憩を挟みつつ集中を維持しましたか？',
        '複数のタスクを切り替える際、速やかに意識を集中できましたか？',
        '午後の眠くなりやすい時間帯でも集中してミスを防げましたか？',
      ],
      '効率性': [
        'ショートカットキーを活用して入力速度を上げられましたか？',
        '優先順位の高いタスクから順序よく処理できましたか？',
        'テンプレートや既存フォーマットを活用して時間を短縮しましたか？',
        '不明点を早めに解消し、作業の手戻りを防げましたか？',
        '予定していた時間内に目標の作業量を完了できましたか？',
      ],
      '理解力': [
        '作業マニュアルや指示書の内容を正しく理解できましたか？',
        '専門用語や社内ルールについて、不明なままにせず確認しましたか？',
        '依頼者の意図を汲み取り、求められている成果物を作成できましたか？',
        '業務フロー全体の流れを把握して作業に取り組めましたか？',
        'フィードバックされた内容の理由を正しく理解し、次に活かせそうですか？',
      ],
      '整理力': [
        'デスク周りやPCのデスクトップは整理整頓されていましたか？',
        '必要な書類やデータをすぐに取り出せる状態に保てましたか？',
        '不要なファイルやメールの削除・整理を行いましたか？',
        'タスクの進捗状況をメモやツールで整理して管理しましたか？',
        '共有フォルダ内のファイル構成を分かりやすく維持できましたか？',
      ],
      '丁寧さ': [
        '電話対応やメールの文面で、丁寧な言葉遣いを心がけましたか？',
        '書類のホチキス止めやファイリングを綺麗に行いましたか？',
        '備品や共有機材を丁寧に扱いましたか？',
        '字を書く際、誰が見ても読みやすい文字を心がけましたか？',
        '挨拶や身だしなみなど、基本的なマナーを大切にしましたか？',
      ],
    };
    return _getQuestionFromMap(questions, category, day, '事務作業');
  }

  // 清掃作業専用の質問
  static String _getCleaningWorkQuestion(String category, int day) {
    final questions = {
      '丁寧さ': [
        '四隅や物陰など、見えにくい場所の汚れも丁寧に落とせましたか？',
        '拭き残しや水滴の跡が残らないよう、綺麗に仕上げられましたか？',
        '備品を動かした際、元の位置に丁寧に戻しましたか？',
        'ガラスや鏡など、指紋を残さずにピカピカに磨けましたか？',
        'お客様や利用者が通る際、丁寧な挨拶や配慮ができましたか？',
      ],
      '体力': [
        '長時間の立ち作業や移動でも、バテずに作業を継続できましたか？',
        '重い機材やゴミの運搬を、安全かつスムーズに行えましたか？',
        '階段の昇り降りや屈伸運動など、身体への負担をコントロールできましたか？',
        '暑さや寒さの中でも、体調管理をしながら作業できましたか？',
        '作業終了まで一定のペースを保って動き続けられましたか？',
      ],
      '協調性': [
        '広いエリアを分担する際、チームと連携して効率よく動けましたか？',
        '作業の遅れている箇所の手伝いやフォローができましたか？',
        '通路を塞がないよう、周囲の状況を見て作業できましたか？',
        '備品の補充や交換の情報をスタッフ間で共有できましたか？',
        'シフト交代時の引き継ぎ事項を漏れなく伝えられましたか？',
      ],
      '正確性': [
        '洗剤の希釈倍率や使用箇所を間違いなく守れましたか？',
        '清掃手順（上から下へ、奥から手前へなど）を正確に守れましたか？',
        '点検表やチェックリストの項目を正確に記入できましたか？',
        'ゴミの分別ルールを厳守して処理できましたか？',
        '危険箇所や破損箇所を見つけた際、規定通りに報告できましたか？',
      ],
      '効率性': [
        '無駄な動きを減らし、最短ルートで移動・作業ができましたか？',
        '汚れの度合いに応じて、適切な道具を素早く選択できましたか？',
        '準備や後片付けの時間を短縮する工夫ができましたか？',
        '二度手間にならないよう、一度で確実に汚れを落とせましたか？',
        '制限時間内に担当エリアを全て完了させられましたか？',
      ],
      '気配り': [
        '利用者が近くにいる時、作業音や埃に配慮しましたか？',
        '滑りやすい床への注意喚起など、安全への配慮ができましたか？',
        'トイレットペーパーや石鹸の補充状況に気を配れましたか？',
        '清潔感のある身だしなみで、利用者に不快感を与えないよう注意しましたか？',
        '「清掃中」の看板を適切な位置に見やすく設置できましたか？',
      ],
    };
    return _getQuestionFromMap(questions, category, day, '清掃作業');
  }

  // 接客業務専用の質問
  static String _getCustomerServiceQuestion(String category, int day) {
    final questions = {
      'コミュニケーション力': [
        'お客様の要望を正確に聞き取り、適切な提案ができましたか？',
        'はっきりとした声で、聞き取りやすいトーンで話せましたか？',
        'お客様の質問に対して、分かりやすく説明できましたか？',
        '困っているお客様に、自ら進んで声をかけられましたか？',
        '感謝や謝罪の言葉を、心を込めて伝えられましたか？',
      ],
      '笑顔': [
        '入店時や退店時、自然で明るい笑顔で挨拶できましたか？',
        'マスク越しでも伝わるような、目元の笑顔を意識しましたか？',
        '忙しい時でも、不機嫌な顔を見せずに笑顔を保てましたか？',
        'お客様と目が合った際、柔和な表情で会釈できましたか？',
        'スタッフ同士の会話でも、明るい表情を心がけましたか？',
      ],
      '丁寧さ': [
        '商品の受け渡し時、両手を添えて丁寧に行えましたか？',
        '言葉遣い（敬語、クッション言葉）を正しく使えましたか？',
        'お釣りを渡す際、お客様が確認しやすいよう丁寧に扱いましたか？',
        '案内をする際、指差しではなく手のひらで方向を示せましたか？',
        'お辞儀の角度や姿勢を意識し、丁寧な振る舞いができましたか？',
      ],
      '正確性': [
        'オーダーの聞き間違いや入力ミスはありませんでしたか？',
        'レジ操作やお会計の計算を正確に行えましたか？',
        '商品の在庫確認や説明内容に誤りはありませんでしたか？',
        '予約の受付日時や人数を正確に記録・管理できましたか？',
        '提供する商品やサービスの順序・セット内容に間違いはありませんでしたか？',
      ],
      '臨機応変': [
        '混雑時、状況を見て優先順位を判断し行動できましたか？',
        'イレギュラーな要望やクレームに対し、落ち着いて対応できましたか？',
        'お子様連れや高齢者など、相手に合わせた配慮ある対応ができましたか？',
        'マニュアルにない事態でも、上司に相談するなど適切に動けましたか？',
        '急な欠品やトラブルの際、代替案をスムーズに提案できましたか？',
      ],
      '気配り': [
        'お客様の水のおかわりや空いたお皿にすぐに気づけましたか？',
        '店内の温度やBGMの音量など、快適な環境作りに気を配れましたか？',
        'お客様が何かを探している様子に、いち早く気づけましたか？',
        '雨天時の傘袋の準備など、状況に合わせた心遣いができましたか？',
        '退店されるお客様を、感謝の気持ちを込めてお見送りできましたか？',
      ],
    };
    return _getQuestionFromMap(questions, category, day, '接客業務');
  }

  // 軽作業専用の質問
  static String _getLightWorkQuestion(String category, int day) {
    final questions = {
      '正確性': [
        'ピッキングリストの品番や数量を指差し確認しましたか？',
        '梱包時、宛先ラベルの貼り間違いがないか確認しましたか？',
        '商品の向きや並べ方を、指定通り正確に行えましたか？',
        '検品作業で、不良品の見落としはありませんでしたか？',
        '在庫数のカウントや記録を、誤差なく行えましたか？',
      ],
      '集中力': [
        '繰り返しの作業でも、漫然とせずに集中して行えましたか？',
        '手元の細かい作業に、視線を外さず没頭できましたか？',
        '作業中の私語を慎み、手元に意識を集中させられましたか？',
        '疲れが出る時間帯でも、ミスが出ないよう集中力を維持しましたか？',
        '急ぎの作業でも、焦らず一つ一つの動作に集中できましたか？',
      ],
      '体力': [
        '重い荷物を持つ際、腰を痛めない正しい姿勢で行えましたか？',
        '立ちっぱなしの作業でも、足腰の負担を軽減する工夫ができましたか？',
        '広い倉庫内の移動でも、疲れを見せずに歩き回れましたか？',
        '作業スピードを落とさず、最後まで体力を維持できましたか？',
        '翌日に疲れを残さないよう、作業後のストレッチなどケアを行いましたか？',
      ],
      '効率性': [
        '動線を意識して、移動距離の少ない順路で作業できましたか？',
        '両手を使って作業するなど、スピードアップの工夫をしましたか？',
        '梱包資材の準備を事前に行い、スムーズに梱包作業に入れましたか？',
        '次に使う道具を取りやすい位置に配置していましたか？',
        '目標個数（ノルマ）を達成するためのペース配分ができましたか？',
      ],
      '丁寧さ': [
        '商品を傷つけないよう、優しく慎重に扱いましたか？',
        '梱包テープをヨレずに真っ直ぐ綺麗に貼れましたか？',
        '緩衝材を適切に入れ、配送中の破損を防ぐ梱包ができましたか？',
        '商品を棚に戻す際、乱雑にならず綺麗に整頓しましたか？',
        '作業台の周りを常に整理整頓し、次に使う人が気持ちよく使えるようにしましたか？',
      ],
      '持久力': [
        '単調な作業の繰り返しでも、モチベーションを維持して続けられましたか？',
        '残業や繁忙期の長時間作業でも、根気強く取り組めましたか？',
        '一定のリズムを保って、ムラのない作業ペースを持続できましたか？',
        '精神的なストレスや飽きを感じても、最後までやり遂げる力がありましたか？',
        '週の後半で疲労が溜まってきても、品質を落とさず作業できましたか？',
      ],
    };
    return _getQuestionFromMap(questions, category, day, '軽作業');
  }

  static String _getQuestionFromMap(
    Map<String, List<String>> questions,
    String category,
    int day,
    String context,
  ) {
    final categoryQuestions = questions[category];
    if (categoryQuestions != null && day < categoryQuestions.length) {
      return categoryQuestions[day];
    }
    return '今日の$context作業は順調でしたか？';
  }

  // 履歴のダミーデータを生成
  static List<WeeklyRecord> getHistory() {
    return [
      WeeklyRecord(
        id: 'WR001',
        title: '動画編集',
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        dailyRecords: _generateDailyRecords(
          DateTime.now().subtract(const Duration(days: 14)),
        ),
      ),
      WeeklyRecord(
        id: 'WR002',
        title: '事務作業',
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        dailyRecords: _generateDailyRecords(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
      ),
    ];
  }

  static List<DailyRecord> _generateDailyRecords(DateTime startOfWeek) {
    List<DailyRecord> records = [];
    for (int i = 0; i < 5; i++) {
      records.add(
        DailyRecord(
          dayIndex: i,
          date: startOfWeek.add(Duration(days: i)),
          answers: {},
          memo: 'Day ${i + 1} memo',
        ),
      );
    }
    return records;
  }
}

// ==========================================
// 3. State Management / 状態管理（アプリの頭脳）
// ==========================================

// アプリ全体で共有するデータや、表示を更新するタイミングを管理する「頭脳」にあたるクラスです。
// 「ChangeNotifier」を継承することで、データの変更を画面に通知できるようになります。
class AppState extends ChangeNotifier {
  // 画面遷移を管理するためのキー。これを使うと、どの画面からでもポップアップなどを出しやすくなります。
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  List<QuestionSet> _questionSets = []; // 利用可能な職種テンプレートのリスト
  QuestionSet? _currentQuestionSet; // 現在選択されている職種

  // ジャンル（職種）ごとの進行中の記録です。
  final Map<String, Map<int, DailyRecord>> _activeRecordsPerGenre = {};
  // ジャンル（職種）ごとの開始日です。
  final Map<String, DateTime> _activeStartDatesPerGenre = {};

  // 現在選択されているジャンルに対応する「今週の記録」を動的に取得します。
  Map<int, DailyRecord> get _currentWeekRecords {
    final genreId = _currentQuestionSet?.id ?? 'default';
    if (!_activeRecordsPerGenre.containsKey(genreId)) {
      _activeRecordsPerGenre[genreId] = {};
    }
    return _activeRecordsPerGenre[genreId]!;
  }

  // 現在選択されているジャンルに対応する「開始日」を動的に取得・設定します。
  DateTime? get _currentWeekStartDate {
    final genreId = _currentQuestionSet?.id ?? 'default';
    return _activeStartDatesPerGenre[genreId];
  }

  set _currentWeekStartDate(DateTime? value) {
    final genreId = _currentQuestionSet?.id ?? 'default';
    if (value == null) {
      _activeStartDatesPerGenre.remove(genreId);
    } else {
      _activeStartDatesPerGenre[genreId] = value;
    }
  }

  // 過去に完了した「履歴」のリストです。
  List<WeeklyRecord> _history = [];

  // アプリが起動したときに最初に実行される処理です。
  AppState() {
    _loadData(); // 保存されているデータを読み込みます。
  }

  // スマホの保存領域からデータを取り出す処理です。
  // 「SharedPreferences」という仕組みを使って、アプリを閉じてもデータが消えないようにしています。
  Future<void> _loadData() async {
    // 最初に職種のテンプレート（ダミーデータ）を準備します。
    _questionSets = DummyData.getQuestionSets();
    _currentQuestionSet = _questionSets.first;

    final prefs = await SharedPreferences.getInstance();

    // 1. 「履歴」の読み込み
    final historyJson = prefs.getString('history');
    if (historyJson != null) {
      // 文字列として保存されているJSON形式を、元のデータの形（WeeklyRecord）に戻します。
      final List<dynamic> decoded = jsonDecode(historyJson);
      _history = decoded.map((e) => WeeklyRecord.fromJson(e)).toList();
    } else {
      _history = [];
    }

    // 4. 「現在選んでいる職種」の読み込み（先に読み込むことで互換データ移行先のジャンルを正しく特定します）
    final currentSetId = prefs.getString('current_question_set_id_v2');
    if (currentSetId != null) {
      try {
        _currentQuestionSet = _questionSets.firstWhere(
          (qs) => qs.id == currentSetId,
        );
      } catch (e) {
        // 見つからなかった場合は何もしません。
      }
    }

    // 2. 「ジャンルごとの記録」の読み込み
    final activeRecordsJson = prefs.getString('active_records_per_genre');
    _activeRecordsPerGenre.clear();
    if (activeRecordsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(activeRecordsJson);
      decoded.forEach((genreId, genreRecordsJson) {
        final Map<int, DailyRecord> recordsMap = {};
        final Map<String, dynamic> genreMap =
            genreRecordsJson as Map<String, dynamic>;
        genreMap.forEach((dayKey, dailyRecordJson) {
          recordsMap[int.parse(dayKey)] = DailyRecord.fromJson(dailyRecordJson);
        });
        _activeRecordsPerGenre[genreId] = recordsMap;
      });
    } else {
      // 互換性維持: 旧「今週の記録」の読み込み
      final currentWeekJson = prefs.getString('current_week_records');
      if (currentWeekJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(currentWeekJson);
        final Map<int, DailyRecord> recordsMap = {};
        decoded.forEach((key, value) {
          recordsMap[int.parse(key)] = DailyRecord.fromJson(value);
        });
        final genreId = _currentQuestionSet?.id ?? 'QS001';
        _activeRecordsPerGenre[genreId] = recordsMap;
      }
    }

    // 3. 「ジャンルごとの開始日」の読み込み
    final startDatesJson = prefs.getString('active_start_dates_per_genre');
    _activeStartDatesPerGenre.clear();
    if (startDatesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(startDatesJson);
      decoded.forEach((genreId, startDateStr) {
        _activeStartDatesPerGenre[genreId] = DateTime.parse(startDateStr);
      });
    } else {
      // 互換性維持: 旧「今週の開始日」の読み込み
      final startDateStr = prefs.getString('current_week_start_date');
      if (startDateStr != null) {
        final genreId = _currentQuestionSet?.id ?? 'QS001';
        _activeStartDatesPerGenre[genreId] = DateTime.parse(startDateStr);
      }
    }

    // データの準備ができたら、画面に「新しくなったよ！」と通知して再描画させます。
    notifyListeners();
  }

  // 今の状態をスマホの保存領域に書き込む処理です。
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 各データをJSON（テキスト形式）に変換して保存します。
    // 「履歴」の保存
    final historyJson = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString('history', historyJson);

    // 「ジャンルごとの記録」の保存
    final Map<String, dynamic> serializedActiveRecords = {};
    _activeRecordsPerGenre.forEach((genreId, recordsMap) {
      final Map<String, dynamic> genreMap = {};
      recordsMap.forEach((dayKey, dailyRecord) {
        genreMap[dayKey.toString()] = dailyRecord.toJson();
      });
      serializedActiveRecords[genreId] = genreMap;
    });
    await prefs.setString(
      'active_records_per_genre',
      jsonEncode(serializedActiveRecords),
    );

    // 「ジャンルごとの開始日」の保存
    final Map<String, String> serializedStartDates = {};
    _activeStartDatesPerGenre.forEach((genreId, startDate) {
      serializedStartDates[genreId] = startDate.toIso8601String();
    });
    await prefs.setString(
      'active_start_dates_per_genre',
      jsonEncode(serializedStartDates),
    );

    // 「現在選んでいる職種」の保存
    if (_currentQuestionSet != null) {
      await prefs.setString(
        'current_question_set_id_v2',
        _currentQuestionSet!.id,
      );
    }
  }

  // ゲッター
  QuestionSet? get currentQuestionSet => _currentQuestionSet;
  List<QuestionSet> get questionSets => _questionSets;
  List<WeeklyRecord> get history => _history;

  // 現在の質問セット（シチュエーション）を変更
  void setCurrentQuestionSet(String questionSetId) {
    final newSet = _questionSets.firstWhere((qs) => qs.id == questionSetId);
    _currentQuestionSet = newSet;
    _saveData(); // 保存
    notifyListeners();
  }

  // 履歴レコードを削除する
  void deleteHistoryRecord(String id) {
    _history.removeWhere((record) => record.id == id);
    _saveData(); // 保存
    notifyListeners();
  }

  // 新しい週を開始する
  void startNewWeek() {
    final now = DateTime.now();
    _currentWeekStartDate = DateTime(
      now.year,
      now.month,
      now.day,
    ); // 時間を切り捨てて日付のみにする
    _currentWeekRecords.clear();
    _saveData(); // 保存
    notifyListeners();
  }

  // 0から4の中で、まだすべての質問に回答し終えていない最初のインデックスを探します。
  // すべて（0〜4）回答し終えている場合は 5 を返します。
  int getTodayIndex() {
    for (int i = 0; i < 5; i++) {
      final questions = getQuestionsForDay(i);
      if (questions.isEmpty) continue;
      final record = _currentWeekRecords[i];
      if (record == null || record.answers.length < questions.length) {
        return i;
      }
    }
    return 5;
  }

  // これまでに回答が完了している最大のインデックス（0〜4）を取得。一つも完了していない場合は -1 を返す。
  int getLastCompletedIndex() {
    int lastCompleted = -1;
    for (int i = 0; i < 5; i++) {
      final questions = getQuestionsForDay(i);
      if (questions.isEmpty) continue;
      final record = _currentWeekRecords[i];
      if (record != null && record.answers.length >= questions.length) {
        lastCompleted = i;
      }
    }
    return lastCompleted;
  }

  // 特定の日の質問リストを取得
  List<Question> getQuestionsForDay(int dayIndex) {
    if (_currentQuestionSet == null) return [];
    return _currentQuestionSet!.questions
        .where((q) => q.dayIndex == dayIndex)
        .toList();
  }

  // 質問文を更新
  void updateQuestionText(
    String questionSetId,
    int dayIndex,
    String category,
    String newText,
  ) {
    final questionSet = _questionSets.firstWhere(
      (qs) => qs.id == questionSetId,
      orElse: () => _questionSets.first, // フォールバック
    );

    final index = questionSet.questions.indexWhere(
      (q) => q.dayIndex == dayIndex && q.category == category,
    );

    if (index != -1) {
      final oldQuestion = questionSet.questions[index];
      questionSet.questions[index] = Question(
        id: oldQuestion.id,
        text: newText,
        category: oldQuestion.category,
        dayIndex: oldQuestion.dayIndex,
      );
      // NOTE: 本来はここで永続化が必要だが、QuestionSet自体の保存ロジックが未実装のため
      // メモリ上の更新のみ行う。アプリ再起動でリセットされる点に注意。
      notifyListeners();
    }
  }

  // 回答を保存
  void saveAnswer(int dayIndex, String questionId, int score) {
    if (_currentWeekStartDate == null) {
      final now = DateTime.now();
      _currentWeekStartDate = DateTime(now.year, now.month, now.day);
    }
    if (!_currentWeekRecords.containsKey(dayIndex)) {
      _currentWeekRecords[dayIndex] = DailyRecord(
        dayIndex: dayIndex,
        date: DateTime.now(),
        answers: {},
      );
    }
    _currentWeekRecords[dayIndex]!.answers[questionId] = score;
    _saveData(); // 保存
    notifyListeners();
  }

  // 全ての日程（0-4）の記録が完了しているか判定
  bool isAllDaysRecorded() {
    for (int i = 0; i < 5; i++) {
      final questions = getQuestionsForDay(i);
      if (questions.isEmpty) return false;
      final record = _currentWeekRecords[i];
      if (record == null || record.answers.length < questions.length) {
        return false;
      }
    }
    return true;
  }

  // 現在の記録を履歴に確定して新しく開始する
  void archiveAndStartNewWeek() {
    saveCurrentWeekToHistory(); // 現在の状態を履歴に保存（または更新）
    _currentWeekRecords.clear(); // 現在の記録をクリア
    _currentWeekStartDate = null; // 開始日をリセット（次回ボタン押下時に設定される）
    _saveData();
    notifyListeners();
  }

  // メモを保存
  void saveMemo(int dayIndex, String memo) {
    if (!_currentWeekRecords.containsKey(dayIndex)) {
      _currentWeekRecords[dayIndex] = DailyRecord(
        dayIndex: dayIndex,
        date: DateTime.now(),
        answers: {},
        memo: memo,
      );
    } else {
      final old = _currentWeekRecords[dayIndex]!;
      _currentWeekRecords[dayIndex] = DailyRecord(
        dayIndex: old.dayIndex,
        date: old.date,
        answers: old.answers,
        memo: memo,
      );
    }
    _saveData(); // 保存
    notifyListeners();
  }

  // 特定の質問のスコアを取得
  int getScore(int dayIndex, String questionId) {
    return _currentWeekRecords[dayIndex]?.answers[questionId] ??
        3; // デフォルトは3（普通）
  }

  // 特定の日のメモを取得
  String getMemo(int dayIndex) {
    return _currentWeekRecords[dayIndex]?.memo ?? '';
  }

  // 今週のカテゴリー別累計スコアを計算
  // 修正: 平均ではなく累計スコアを返すように変更
  Map<String, double> getCurrentWeekAverages() {
    if (_currentQuestionSet == null) return {};

    Map<String, int> categoryScores = {};

    // 初期化 - 現在のQuestionSetのカテゴリーを使用
    for (var cat in _currentQuestionSet!.categories) {
      categoryScores[cat] = 0;
    }

    // 全ての記録を集計
    for (var entry in _currentWeekRecords.entries) {
      final record = entry.value;
      for (var answerEntry in record.answers.entries) {
        final qId = answerEntry.key;
        final score = answerEntry.value;
        // 質問IDからカテゴリーを特定
        final question = _currentQuestionSet!.questions.firstWhere(
          (q) => q.id == qId,
          orElse: () => Question(id: '', text: '', category: '', dayIndex: 0),
        );
        if (question.category.isNotEmpty &&
            categoryScores.containsKey(question.category)) {
          categoryScores[question.category] =
              (categoryScores[question.category] ?? 0) + score;
        }
      }
    }

    // double型に変換して返す
    return categoryScores.map((key, value) => MapEntry(key, value.toDouble()));
  }

  // 最新のレーダーチャートデータを取得（ホーム画面用）
  // 修正: その日までの累計スコアを計算して返す
  Map<String, double> getLatestRadarData() {
    // 1. 回答済みの記録がある場合
    final lastCompleted = getLastCompletedIndex();
    if (lastCompleted >= 0) {
      return _calculateCumulativeScoresUpTo(lastCompleted);
    }

    // 2. 履歴がある場合
    if (_history.isNotEmpty) {
      final latestWeeklyRecord = _history.first;
      return _calculateCumulativeScoresFromHistory(latestWeeklyRecord);
    }

    // 3. データがない場合は現在のカテゴリーで全て-1を返す（中心点に表示）
    if (_currentQuestionSet != null) {
      return {for (var cat in _currentQuestionSet!.categories) cat: -1.0};
    }
    return {};
  }

  // 指定した日までの累計スコアを計算
  Map<String, double> _calculateCumulativeScoresUpTo(int targetDayIndex) {
    if (_currentQuestionSet == null) return {};

    Map<String, int> categoryScores = {};
    // 現在のQuestionSetのカテゴリーを使用
    for (var cat in _currentQuestionSet!.categories) {
      categoryScores[cat] = 0;
    }

    for (var entry in _currentWeekRecords.entries) {
      if (entry.key <= targetDayIndex) {
        final record = entry.value;
        for (var answerEntry in record.answers.entries) {
          final qId = answerEntry.key;
          final score = answerEntry.value;
          final question = _currentQuestionSet!.questions.firstWhere(
            (q) => q.id == qId,
            orElse: () => Question(id: '', text: '', category: '', dayIndex: 0),
          );
          if (question.category.isNotEmpty &&
              categoryScores.containsKey(question.category)) {
            categoryScores[question.category] =
                (categoryScores[question.category] ?? 0) + score;
          }
        }
      }
    }
    return categoryScores.map((key, value) => MapEntry(key, value.toDouble()));
  }

  // 履歴レコードから累計スコアを計算
  Map<String, double> _calculateCumulativeScoresFromHistory(
    WeeklyRecord record,
  ) {
    if (_currentQuestionSet == null) return {};

    Map<String, int> categoryScores = {};
    // 現在のQuestionSetのカテゴリーを使用
    for (var cat in _currentQuestionSet!.categories) {
      categoryScores[cat] = 0;
    }

    // 履歴の全てのDailyRecordを集計（週の終わり時点の状態）
    for (var dailyRecord in record.dailyRecords) {
      for (var answerEntry in dailyRecord.answers.entries) {
        final qId = answerEntry.key;
        final score = answerEntry.value;
        // 履歴の場合、QuestionSetが切り替わっている可能性があるため、
        // 本当はQuestionSetの情報も履歴に持たせるべきだが、
        // ここでは現在のセットまたはダミーデータから推測する簡易実装とする。
        // ※厳密には履歴保存時にカテゴリーごとのスコアを保存すべき。

        // 暫定対応: 現在のセットから探す。なければ無視。
        final question = _currentQuestionSet!.questions.firstWhere(
          (q) => q.id == qId,
          orElse: () => Question(id: '', text: '', category: '', dayIndex: 0),
        );
        if (question.category.isNotEmpty &&
            categoryScores.containsKey(question.category)) {
          categoryScores[question.category] =
              (categoryScores[question.category] ?? 0) + score;
        }
      }
    }
    return categoryScores.map((key, value) => MapEntry(key, value.toDouble()));
  }

  // 先週の記録から指定した日までの累計スコアを取得
  Map<String, double> getPreviousWeekScoresUpToDay(int targetDayIndex) {
    if (_currentQuestionSet == null || _history.isEmpty) {
      return {}; // データがない場合は空を返す
    }

    // 現在のジャンル（タイトル）と同じで、かつ現在のセッション（開始日が同じ）ではない最新の履歴レコードを検索
    WeeklyRecord? previousRecord;
    try {
      previousRecord = _history.firstWhere((record) {
        final isSameTitle = record.title == _currentQuestionSet!.title;
        final isSameStartDate =
            _currentWeekStartDate != null &&
            record.startDate.year == _currentWeekStartDate!.year &&
            record.startDate.month == _currentWeekStartDate!.month &&
            record.startDate.day == _currentWeekStartDate!.day;
        return isSameTitle && !isSameStartDate;
      });
    } catch (e) {
      previousRecord = null;
    }

    if (previousRecord == null) {
      return {}; // 一致するジャンルがない場合は空を返す
    }

    Map<String, int> categoryScores = {};
    for (var cat in _currentQuestionSet!.categories) {
      categoryScores[cat] = 0;
    }

    bool hasAnyData = false;
    // targetDayIndexまでのDailyRecordを集計
    for (
      int i = 0;
      i <= targetDayIndex && i < previousRecord.dailyRecords.length;
      i++
    ) {
      final dailyRecord = previousRecord.dailyRecords[i];
      if (dailyRecord.answers.isEmpty) continue;

      hasAnyData = true;
      for (var answerEntry in dailyRecord.answers.entries) {
        final qId = answerEntry.key;
        final score = answerEntry.value;

        final question = _currentQuestionSet!.questions.firstWhere(
          (q) => q.id == qId,
          orElse: () => Question(id: '', text: '', category: '', dayIndex: 0),
        );
        if (question.category.isNotEmpty &&
            categoryScores.containsKey(question.category)) {
          categoryScores[question.category] =
              (categoryScores[question.category] ?? 0) + score;
        }
      }
    }

    if (!hasAnyData) {
      // データがない場合は-1を返す
      return {for (var cat in _currentQuestionSet!.categories) cat: -1.0};
    }

    return categoryScores.map((key, value) => MapEntry(key, value.toDouble()));
  }

  // _convertRecordToRadarData は不要になったため削除、または単日計算用に残すなら修正が必要だが、
  // 今回の要件（累計）では上記メソッドで代替する。

  // 今週の記録を履歴に保存し、リセットする
  void saveCurrentWeekToHistory() {
    if (_currentWeekRecords.isEmpty) return;

    // 開始日が不明な場合は、記録されている一番早い日付をDay 1とする
    DateTime startDate =
        _currentWeekStartDate ??
        _currentWeekRecords.values
            .reduce((a, b) => a.date.isBefore(b.date) ? a : b)
            .date;

    // 最新の回答日（最後のセッションの日付）を取得
    DateTime latestAnswerDate = startDate;
    for (final record in _currentWeekRecords.values) {
      if (record.date.isAfter(latestAnswerDate)) {
        latestAnswerDate = record.date;
      }
    }

    List<DailyRecord> completeDailyRecords = [];
    for (int i = 0; i < 5; i++) {
      if (_currentWeekRecords.containsKey(i)) {
        completeDailyRecords.add(_currentWeekRecords[i]!);
      } else {
        // 欠けている回のデータを最新日付で補完（日付の連続性は不要）
        completeDailyRecords.add(
          DailyRecord(
            dayIndex: i,
            date: latestAnswerDate,
            answers: {},
            memo: '',
          ),
        );
      }
    }

    final newHistoryRecord = WeeklyRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _currentQuestionSet?.title ?? '未設定',
      startDate: startDate,
      dailyRecords: completeDailyRecords,
    );

    // 既存の履歴（最新）と同じ週・同じタイトルならマージ（更新）する
    if (_history.isNotEmpty) {
      final latest = _history.first;
      // 日付の比較（時分秒を無視）
      final isSameDate =
          latest.startDate.year == startDate.year &&
          latest.startDate.month == startDate.month &&
          latest.startDate.day == startDate.day;

      if (isSameDate && latest.title == newHistoryRecord.title) {
        // 更新: IDは維持し、dailyRecordsを新しいものに置き換える
        _history[0] = WeeklyRecord(
          id: latest.id,
          title: latest.title,
          startDate: latest.startDate,
          dailyRecords: completeDailyRecords,
        );
      } else {
        // 新規追加
        _history.insert(0, newHistoryRecord);
      }
    } else {
      // 新規追加
      _history.insert(0, newHistoryRecord);
    }

    // _currentWeekRecords.clear(); // 保存時にクリアしない（継続して入力できるようにするため）
    // _currentWeekStartDate = null; // 週の開始日もリセットしない
    _saveData(); // 保存
    notifyListeners();
  }
}

// ==========================================
// 4. UI Screens / 画面の構成
// ==========================================

// 1. ホーム画面
// アプリを立ち上げて最初に表示される、メインの画面です。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final radarData = appState.getLatestRadarData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('適性診断'),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      // グラデーション背景
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () => Navigator.pushNamed(context, '/history'),
                      tooltip: '過去の記録',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => Navigator.pushNamed(context, '/question_edit'),
                      tooltip: '質問編集',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 見出しを表示します。
                Text(
                  '今週の成長記録',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // シチュエーション選択（職種選び）のドロップダウンメニューです。
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '今日の作業内容：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: appState.currentQuestionSet?.id,
                            isExpanded: true,
                            items:
                                appState.questionSets.map((qs) {
                                  return DropdownMenuItem(
                                    value: qs.id,
                                    child: Text(qs.title),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                // 職種が変更されたら、AppStateに伝えて保存・更新します。
                                appState.setCurrentQuestionSet(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 「今日の質問に答える」ボタン
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Builder(
                    builder: (context) {
                      final lastCompleted = appState.getLastCompletedIndex();
                      String buttonText;
                      if (lastCompleted == -1) {
                        buttonText = '診断を始める (Day 1)';
                      } else if (lastCompleted >= 4) {
                        buttonText = '診断結果を見る';
                      } else {
                        buttonText = '診断を受ける (Day ${lastCompleted + 2})';
                      }

                      return ElevatedButton(
                        onPressed: () {
                          int dayIndex = appState.getTodayIndex();
                          if (dayIndex > 4) {
                            Navigator.pushNamed(
                              context,
                              '/result',
                              arguments: 4,
                            );
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            '/question',
                            arguments: dayIndex,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(buttonText),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                // レーダーチャート表示エリア
                Container(
                  height: 400, // 高さを固定
                  width: double.infinity, // 横幅いっぱい
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int lastCompleted = appState.getLastCompletedIndex();
                      if (lastCompleted < 0) lastCompleted = 0;
                      if (lastCompleted > 4) lastCompleted = 4;

                      final double maxScore = (lastCompleted + 1) * 4.0;

                      return RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              fillColor: Colors.blue.withValues(alpha: 0.2),
                              borderColor: Colors.blue,
                              entryRadius: 3,
                              dataEntries:
                                  (appState.currentQuestionSet?.categories ??
                                          [])
                                      .map((cat) {
                                        // データがなければ-1（中心点）を表示
                                        final value = radarData[cat];
                                        return RadarEntry(value: value ?? -1.0);
                                      })
                                      .toList(),
                            ),
                            // 透明なデータセットを追加してスケールを固定 (Max)
                            RadarDataSet(
                              fillColor: Colors.transparent,
                              borderColor: Colors.transparent,
                              entryRadius: 0,
                              dataEntries:
                                  (appState.currentQuestionSet?.categories ??
                                          [])
                                      .map((cat) {
                                        return RadarEntry(value: maxScore);
                                      })
                                      .toList(),
                            ),
                            // 最小値を-1に固定するための透明なデータセット
                            RadarDataSet(
                              fillColor: Colors.transparent,
                              borderColor: Colors.transparent,
                              entryRadius: 0,
                              dataEntries:
                                  (appState.currentQuestionSet?.categories ??
                                          [])
                                      .map((cat) {
                                        return const RadarEntry(value: -1.0);
                                      })
                                      .toList(),
                            ),
                          ],
                          isMinValueAtCenter: true,
                          radarBackgroundColor: Colors.transparent,
                          borderData: FlBorderData(show: false),
                          radarBorderData: const BorderSide(color: Colors.grey),
                          titlePositionPercentageOffset: 0.2,
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                          getTitle: (index, angle) {
                            final cats =
                                appState.currentQuestionSet?.categories ?? [];
                            return RadarChartTitle(
                              text: index < cats.length ? cats[index] : '',
                              angle: 0,
                            );
                          },
                          tickCount: 5, // 5分割で6つの同心円（-1,0,1,2,3,4）
                          ticksTextStyle: const TextStyle(
                            color: Colors.transparent,
                          ),
                          tickBorderData: const BorderSide(color: Colors.grey),
                          gridBorderData: const BorderSide(
                            color: Colors.grey,
                            width: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                // デバッグ用: 日付選択ボタン
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '【動作確認用】日付選択',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(5, (index) {
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/question',
                                arguments: index,
                              );
                            },
                            onLongPress: () {
                              // デバッグ用: 長押しで直接その日のResultScreenへ
                              Navigator.pushNamed(
                                context,
                                '/result',
                                arguments: index,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(60, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: Text('Day ${index + 1}'),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 2. 質問画面
// 実際に質問に答えていく画面です。
class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _currentQuestionIndex = 0;
  final TextEditingController _memoController = TextEditingController();
  List<Question> _questions = [];
  int _dayIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _dayIndex = args;
      final appState = Provider.of<AppState>(context, listen: false);
      _questions = appState.getQuestionsForDay(_dayIndex);
      // 既存のメモがあれば表示
      _memoController.text = appState.getMemo(_dayIndex);
    }
  }

  // ボタンが押されたときの処理
  void _handleAnswer(int score) {
    final appState = Provider.of<AppState>(context, listen: false);
    // 回答を保存します。
    appState.saveAnswer(_dayIndex, _questions[_currentQuestionIndex].id, score);

    // 次の質問があれば進み、なければ結果画面へ移動します。
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // 最後の質問回答後にメモも一緒に保存します。
      appState.saveMemo(_dayIndex, _memoController.text);
      // 「pushReplacementNamed」を使うと、戻るボタンで質問画面に戻れなくなるので便利です。
      Navigator.pushReplacementNamed(context, '/result', arguments: _dayIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('質問')),
        body: const Center(child: Text('今日の質問はありません')),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('質問 ${_currentQuestionIndex + 1}/${_questions.length}'),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 進捗バー
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 30),
              Text(
                question.category,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                question.text,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                '今日のメモ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _memoController,
                maxLines: 1,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '気付いたことや感想を入力してください',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildRatingButtons(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRatingButtons() {
    final ratings = [
      {'label': 'とても良い', 'score': 4, 'color': Colors.blue},
      {'label': '良い', 'score': 3, 'color': Colors.lightBlue},
      {'label': '普通', 'score': 2, 'color': Colors.green},
      {'label': '悪い', 'score': 1, 'color': Colors.orange},
      {'label': 'とても悪い', 'score': 0, 'color': Colors.red},
    ];

    return ratings.map((rating) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => _handleAnswer(rating['score'] as int),
            style: ElevatedButton.styleFrom(
              backgroundColor: (rating['color'] as Color).withValues(
                alpha: 0.1,
              ),
              foregroundColor: rating['color'] as Color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: rating['color'] as Color),
              ),
            ),
            child: Text(
              rating['label'] as String,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// 3. 結果画面
// 診断が終わったあとに、レーダーチャートで結果を確認する画面です。
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showComparison = false;

  void _showNewRecordDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('記録完了'),
          content: const Text(
            'Day 1からDay 5までの診断がすべて完了しました。\n現在の記録を履歴に確定し、新しくDay 1から記録を開始しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 「いいえ」の場合はリセットせずに保存して履歴画面へ
                appState.saveCurrentWeekToHistory();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('履歴に保存しました')));
                Navigator.pushReplacementNamed(context, '/history');
              },
              child: const Text('いいえ'),
            ),
            ElevatedButton(
              onPressed: () {
                appState.archiveAndStartNewWeek();
                Navigator.pop(context); // ダイアログを閉じる
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                ); // ホーム画面に戻る
                ScaffoldMessenger.of(
                  appState.navigatorKey.currentContext!,
                ).showSnackBar(const SnackBar(content: Text('新しい記録を開始しました')));
              },
              child: const Text('はい'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentAverages = appState.getCurrentWeekAverages();

    // 引数からDay indexを取得（なければ今日のindexをフォールバック）
    final args = ModalRoute.of(context)?.settings.arguments;
    int todayIndex;
    if (args is int) {
      todayIndex = args;
    } else {
      todayIndex = appState.getTodayIndex();
    }

    if (todayIndex < 0) todayIndex = 0;
    if (todayIndex > 4) todayIndex = 4;

    // 先週の同じDayまでの累計スコアを取得
    final previousAverages = appState.getPreviousWeekScoresUpToDay(todayIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: const Color(0xFFFFFFFF),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('今週の成長記録', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 現在の最大スコアを計算 (Day数 * 4点)
                    int todayIndex = appState.getTodayIndex();
                    if (todayIndex < 0) todayIndex = 0;
                    if (todayIndex > 4) todayIndex = 4;

                    final double maxScore = (todayIndex + 1) * 4.0;

                    // レーダーチャートのロジック
                    return RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            fillColor: Colors.blue.withValues(alpha: 0.2),
                            borderColor: Colors.blue,
                            entryRadius: 3,
                            dataEntries:
                                (appState.currentQuestionSet?.categories ?? [])
                                    .map((cat) {
                                      return RadarEntry(
                                        value: currentAverages[cat] ?? 0.0,
                                      );
                                    })
                                    .toList(),
                          ),
                          if (_showComparison && previousAverages.isNotEmpty)
                            RadarDataSet(
                              fillColor: Colors.grey.withValues(alpha: 0.2),
                              borderColor: Colors.grey,
                              entryRadius: 2,
                              dataEntries:
                                  (appState.currentQuestionSet?.categories ??
                                          [])
                                      .map((cat) {
                                        return RadarEntry(
                                          value: previousAverages[cat] ?? 0.0,
                                        );
                                      })
                                      .toList(),
                            ),
                          // 透明なデータセットを追加してスケールを固定
                          RadarDataSet(
                            fillColor: Colors.transparent,
                            borderColor: Colors.transparent,
                            entryRadius: 0,
                            dataEntries:
                                (appState.currentQuestionSet?.categories ?? [])
                                    .map((cat) {
                                      return RadarEntry(value: maxScore);
                                    })
                                    .toList(),
                          ),
                          // 最小値を-1に固定するための透明なデータセット
                          RadarDataSet(
                            fillColor: Colors.transparent,
                            borderColor: Colors.transparent,
                            entryRadius: 0,
                            dataEntries:
                                (appState.currentQuestionSet?.categories ?? [])
                                    .map((cat) {
                                      return const RadarEntry(value: -1.0);
                                    })
                                    .toList(),
                          ),
                        ],
                        isMinValueAtCenter: true,
                        radarBackgroundColor: Colors.transparent,
                        borderData: FlBorderData(show: false),
                        radarBorderData: const BorderSide(color: Colors.grey),
                        titlePositionPercentageOffset: 0.2,
                        titleTextStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        getTitle: (index, angle) {
                          final cats =
                              appState.currentQuestionSet?.categories ?? [];
                          return RadarChartTitle(
                            text: index < cats.length ? cats[index] : '',
                            angle: 0,
                          );
                        },
                        tickCount: 5, // 5分割で6つの同心円
                        ticksTextStyle: const TextStyle(
                          color: Colors.transparent,
                        ),
                        tickBorderData: const BorderSide(color: Colors.grey),
                        gridBorderData: const BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // 「先週と比較する」スイッチ
              SwitchListTile(
                title: const Text('先週と比較する'),
                subtitle: const Text('同じ職種の過去の記録を重ねて表示します'),
                value: _showComparison,
                onChanged: (value) {
                  setState(() {
                    _showComparison = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (appState.isAllDaysRecorded()) {
                      _showNewRecordDialog(context, appState);
                    } else {
                      appState.saveCurrentWeekToHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('履歴に保存しました')),
                      );
                      Navigator.pushReplacementNamed(context, '/history');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('履歴に保存する'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                  child: const Text('ホームに戻る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. 履歴画面
// これまでに保存した過去の診断結果を一覧で表示する画面です。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final history = appState.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('過去の記録'),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        // 保存されている履歴の数だけ、リストの項目（カード）を作ります。
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final record = history[index];
            return _buildHistoryTile(context, record);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, WeeklyRecord record) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    // 開始日は先頭の回答日（または startDate）
    DateTime actualStartDate = record.startDate;
    if (record.dailyRecords.isNotEmpty) {
      actualStartDate = record.dailyRecords.first.date;
    }

    // 5回すべてに回答があれば「完了」とみなし、終了日も表示する
    final bool isCompleted = record.dailyRecords.length >= 5 &&
        record.dailyRecords.every((r) => r.answers.isNotEmpty);

    // 終了日は最後の回答があるセッションの日付
    DateTime? actualEndDate;
    if (isCompleted) {
      // 回答が存在する最後のセッションの日付を取得
      final answeredRecords = record.dailyRecords.where((r) => r.answers.isNotEmpty).toList();
      if (answeredRecords.isNotEmpty) {
        actualEndDate = answeredRecords.last.date;
      }
    }

    final String periodText = (isCompleted && actualEndDate != null)
        ? '${dateFormat.format(actualStartDate)}〜${dateFormat.format(actualEndDate)}'
        : '${dateFormat.format(actualStartDate)}〜';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryDetailScreen(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: Colors.blue.withValues(alpha: 0.2),
                        borderColor: Colors.blue,
                        entryRadius: 0,
                        dataEntries:
                            List.generate(6, (index) {
                              // 履歴リスト用のダミーデータ
                              return const RadarEntry(value: 3.0);
                            }).toList(),
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData: const BorderSide(
                      color: Colors.transparent,
                    ),
                    titlePositionPercentageOffset: 0.1,
                    titleTextStyle: const TextStyle(fontSize: 0),
                    tickCount: 1,
                    ticksTextStyle: const TextStyle(fontSize: 0),
                    tickBorderData: const BorderSide(color: Colors.transparent),
                    gridBorderData: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'コメント: 今週は集中力が課題でした。', // ダミーコメント
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('確認'),
                          content: const Text('この履歴を削除してもよろしいですか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<AppState>(
                                  context,
                                  listen: false,
                                ).deleteHistoryRecord(record.id);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                '削除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                },
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. 履歴詳細画面
// 過去の診断の1日ごとの変化を詳しく見る画面です。
class HistoryDetailScreen extends StatefulWidget {
  final WeeklyRecord record;

  const HistoryDetailScreen({super.key, required this.record});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _isOverlayMode = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final categories =
        appState.currentQuestionSet?.categories ?? DummyData.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          () {
            final fmt = DateFormat('yyyy/MM/dd');
            final startStr = fmt.format(widget.record.startDate);
            final answeredRecords = widget.record.dailyRecords.where((r) => r.answers.isNotEmpty).toList();
            final isCompleted = answeredRecords.length >= 5;
            if (isCompleted && answeredRecords.isNotEmpty) {
              final endStr = fmt.format(answeredRecords.last.date);
              return '$startStr〜$endStr の詳細';
            }
            return '$startStr〜 の詳細';
          }(),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 重ねて表示ボタン
            GestureDetector(
              onTap: () {
                setState(() {
                  _isOverlayMode = !_isOverlayMode;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isOverlayMode ? '個別表示に戻す' : '重ねて表示する',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isOverlayMode
                      ? _buildOverlayChart(categories)
                      : _buildVerticalList(categories),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalList(List<String> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.record.dailyRecords.length,
      itemBuilder: (context, index) {
        final dailyRecord = widget.record.dailyRecords[index];
        // 累計スコアと最大値を計算
        final maxScore = (index + 1) * 4.0;
        final isAnswersEmpty = dailyRecord.answers.isEmpty;

        final cumulativeEntries =
            isAnswersEmpty
                ? categories.map((_) => const RadarEntry(value: -1.0)).toList()
                : _getCumulativeEntries(index, categories);

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          color: Colors.white.withValues(alpha: 0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isAnswersEmpty
                      ? 'Day ${index + 1} (--/--)'
                      : 'Day ${index + 1} (${DateFormat('MM/dd').format(dailyRecord.date)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: Colors.blue.withValues(alpha: 0.2),
                          borderColor: Colors.blue,
                          entryRadius: 3,
                          dataEntries: cumulativeEntries,
                        ),
                        // 透明なデータセットでスケール固定 (Max)
                        RadarDataSet(
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          entryRadius: 0,
                          dataEntries:
                              categories
                                  .map((_) => RadarEntry(value: maxScore))
                                  .toList(),
                        ),
                        // 最小値を-1に固定するための透明なデータセット
                        RadarDataSet(
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          entryRadius: 0,
                          dataEntries:
                              categories
                                  .map((_) => const RadarEntry(value: -1.0))
                                  .toList(),
                        ),
                      ],
                      isMinValueAtCenter: true,
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(color: Colors.grey),
                      titlePositionPercentageOffset: 0.2,
                      titleTextStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text:
                              index < categories.length
                                  ? categories[index]
                                  : '',
                          angle: 0,
                        );
                      },
                      tickCount: 5,
                      ticksTextStyle: const TextStyle(
                        color: Colors.transparent,
                      ),
                      tickBorderData: const BorderSide(color: Colors.grey),
                      gridBorderData: const BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                if (dailyRecord.memo.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('メモ: ${dailyRecord.memo}'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayChart(List<String> categories) {
    // 最大値はDay 5 (または記録日数) * 4
    final maxScore = widget.record.dailyRecords.length * 4.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.all(16),
        child: RadarChart(
          RadarChartData(
            dataSets: [
              ...List.generate(widget.record.dailyRecords.length, (index) {
                final dailyRecord = widget.record.dailyRecords[index];
                final isAnswersEmpty = dailyRecord.answers.isEmpty;

                // 灰色から紫色へのグラデーション
                final progress =
                    index /
                    (widget.record.dailyRecords.length - 1 == 0
                        ? 1
                        : widget.record.dailyRecords.length - 1);
                final color =
                    Color.lerp(Colors.grey, Colors.purple, progress) ??
                    Colors.purple;

                return RadarDataSet(
                  fillColor: Colors.transparent,
                  borderColor: color,
                  entryRadius: 2,
                  borderWidth: 2,
                  dataEntries:
                      isAnswersEmpty
                          ? categories
                              .map((_) => const RadarEntry(value: -1.0))
                              .toList()
                          : _getCumulativeEntries(index, categories),
                );
              }),
              // スケール固定用 (Max)
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: Colors.transparent,
                entryRadius: 0,
                dataEntries:
                    categories.map((_) => RadarEntry(value: maxScore)).toList(),
              ),
              // 最小値を-1に固定するための透明なデータセット
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: Colors.transparent,
                entryRadius: 0,
                dataEntries:
                    categories
                        .map((_) => const RadarEntry(value: -1.0))
                        .toList(),
              ),
            ],
            isMinValueAtCenter: true,
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: const BorderSide(color: Colors.grey),
            titlePositionPercentageOffset: 0.2,
            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 12),
            getTitle: (index, angle) {
              return RadarChartTitle(
                text: index < categories.length ? categories[index] : '',
                angle: 0,
              );
            },
            tickCount: 5,
            ticksTextStyle: const TextStyle(color: Colors.transparent),
            tickBorderData: const BorderSide(color: Colors.grey),
            gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
      ),
    );
  }

  // 指定したインデックス（日）までの累計スコアを取得
  List<RadarEntry> _getCumulativeEntries(
    int targetIndex,
    List<String> categories,
  ) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentSet = appState.currentQuestionSet; // 注意: 履歴のカテゴリーと一致しない可能性あり

    Map<String, double> cumulativeScores = {};
    for (var cat in categories) {
      cumulativeScores[cat] = 0.0;
    }

    // targetIndexまでの記録を足し合わせる
    for (int i = 0; i <= targetIndex; i++) {
      if (i >= widget.record.dailyRecords.length) break;

      final dailyRecord = widget.record.dailyRecords[i];
      for (var entry in dailyRecord.answers.entries) {
        final qId = entry.key;
        final score = entry.value;

        // 質問IDからカテゴリーを特定（簡易実装）
        // 本来は履歴にカテゴリー情報を持たせるべき
        try {
          // 現在のセットから探すか、IDから推測するか...
          // ここでは現在のセットから探す（不完全だが既存ロジック踏襲）
          if (currentSet != null) {
            final q = currentSet.questions.firstWhere(
              (q) => q.id == qId,
              orElse:
                  () => Question(id: '', text: '', category: '', dayIndex: 0),
            );
            if (q.category.isNotEmpty &&
                cumulativeScores.containsKey(q.category)) {
              cumulativeScores[q.category] =
                  (cumulativeScores[q.category] ?? 0) + score;
            }
          }
        } catch (e) {
          // ignore
        }
      }
    }

    return categories.map((cat) {
      return RadarEntry(value: cumulativeScores[cat] ?? 0.0);
    }).toList();
  }
}

// 6. 質問編集画面
// 診断に使用する職種テンプレートの「質問文」や「カテゴリー名」を変更できる画面です。
class QuestionEditScreen extends StatefulWidget {
  const QuestionEditScreen({super.key});

  @override
  State<QuestionEditScreen> createState() => _QuestionEditScreenState();
}

class _QuestionEditScreenState extends State<QuestionEditScreen> {
  String? _selectedSetId;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final questionSets = appState.questionSets;
    // 選択されている質問セット、またはデフォルト（最初のセット）を取得します。
    final selectedSet = questionSets.firstWhere(
      (qs) => qs.id == (_selectedSetId ?? questionSets.first.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('質問編集'),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDFBFFF)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              // どの職種（シチュエーション）を編集するか選ぶボックスです。
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'シチュエーション選択',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSetId ?? questionSets.first.id,
                    isDense: true,
                    items:
                        questionSets.map((qs) {
                          return DropdownMenuItem(
                            value: qs.id,
                            child: Text(qs.title),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        // 編集対象の職種を切り替えます。
                        _selectedSetId = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  // カテゴリー編集セクション
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '評価カテゴリー（6項目）',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed:
                                  () => _showCategoryEditDialog(
                                    context,
                                    selectedSet,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              selectedSet.categories.map((cat) {
                                return Chip(
                                  label: Text(cat),
                                  backgroundColor: Colors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 2),
                  // 質問編集セクション
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '質問項目（5日間 x 6カテゴリー = 30問）',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5, // 5 Days
                    itemBuilder: (context, dayIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ExpansionTile(
                            title: Text('Day ${dayIndex + 1}'),
                            childrenPadding: const EdgeInsets.all(8.0),
                            children:
                                selectedSet.categories.map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        title: Text(category),
                                        subtitle: Text(
                                          selectedSet.questions
                                              .firstWhere(
                                                (q) =>
                                                    q.dayIndex == dayIndex &&
                                                    q.category == category,
                                                orElse:
                                                    () => Question(
                                                      id: '',
                                                      text: '質問内容を設定...',
                                                      category: '',
                                                      dayIndex: 0,
                                                    ),
                                              )
                                              .text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        trailing: const Icon(Icons.edit),
                                        onTap: () {
                                          _showEditDialog(
                                            context,
                                            selectedSet,
                                            category,
                                            dayIndex,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新規作成ロジック（未実装）
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryEditDialog(BuildContext context, QuestionSet questionSet) {
    final controllers =
        questionSet.categories
            .map((cat) => TextEditingController(text: cat))
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリーを編集'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: 'カテゴリー ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    QuestionSet questionSet,
    String category,
    int dayIndex,
  ) {
    // 該当する質問を取得
    final question = questionSet.questions.firstWhere(
      (q) => q.dayIndex == dayIndex && q.category == category,
      orElse:
          () => Question(
            id: '',
            text: '',
            category: category,
            dayIndex: dayIndex,
          ),
    );

    final controller = TextEditingController(text: question.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$category (Day ${dayIndex + 1})'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '質問文を入力',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.updateQuestionText(
                  questionSet.id,
                  dayIndex,
                  category,
                  controller.text,
                );
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}
