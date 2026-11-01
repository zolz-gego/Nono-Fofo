import 'dart:ui' show Color;

/// Settings from `assets/content/games/cards.json`. Defaults here are only
/// used for keys missing from the file.
class CardsConfig {
  const CardsConfig({
    this.cardCounts = const [4, 8, 16, 32, 64],
    this.phoneMaxCards = 32,
    this.smallScreenWidth = 600,
    this.heroRun = const Duration(milliseconds: 450),
    this.mismatchShow = const Duration(milliseconds: 1000),
    this.nameBubble = const Duration(milliseconds: 1500),
    this.letterColors = const [],
    this.soundless = const {},
    this.background,
    this.cardBack,
  });

  factory CardsConfig.fromJson(Map<String, dynamic> json) {
    const d = CardsConfig();
    final art = json['art'] as Map<String, dynamic>? ?? const {};
    Duration? ms(String key) {
      final v = json[key] as num?;
      return v == null ? null : Duration(milliseconds: v.toInt());
    }

    return CardsConfig(
      cardCounts:
          (json['cardCounts'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          d.cardCounts,
      phoneMaxCards:
          (json['phoneMaxCards'] as num?)?.toInt() ?? d.phoneMaxCards,
      smallScreenWidth:
          (json['smallScreenWidth'] as num?)?.toDouble() ?? d.smallScreenWidth,
      heroRun: ms('heroRunMs') ?? d.heroRun,
      mismatchShow: ms('mismatchShowMs') ?? d.mismatchShow,
      nameBubble: ms('nameBubbleMs') ?? d.nameBubble,
      letterColors:
          (json['letterColors'] as List?)
              ?.map((e) => _hex(e as String))
              .toList() ??
          d.letterColors,
      soundless:
          (json['soundless'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          d.soundless,
      background: art['background'] as String?,
      cardBack: art['cardBack'] as String?,
    );
  }

  /// The levels: how many cards are on the table.
  final List<int> cardCounts;

  /// Phones don't offer levels with more cards than this.
  final int phoneMaxCards;

  /// Screens whose shortest side is under this are "small": no brothers
  /// standing by the table, and fewer levels.
  final double smallScreenWidth;

  /// Time for the brother to reach a card; it flips when he gets there.
  final Duration heroRun;

  /// How long two different cards stay face up.
  final Duration mismatchShow;

  /// How long the letter's name bubble stays after a flip.
  final Duration nameBubble;

  /// One colour per letter, in the alphabet order of letters.json.
  final List<Color> letterColors;

  /// Level 2: what a sound card shows for a letter with no sounds, by
  /// letter id (So: "6").
  final Map<String, String> soundless;

  /// Seaside picture behind the table (drawn in code without it).
  final String? background;

  /// Picture on the back of every card (drawn in code without it).
  final String? cardBack;

  bool isSmallScreen(double shortestSide) => shortestSide < smallScreenWidth;

  /// The levels this screen offers.
  List<int> levelsFor(double shortestSide) => [
    for (final n in cardCounts)
      if (!isSmallScreen(shortestSide) || n <= phoneMaxCards) n,
  ];

  static Color _hex(String s) =>
      Color(int.parse(s.replaceFirst('#', ''), radix: 16) | 0xFF000000);
}
