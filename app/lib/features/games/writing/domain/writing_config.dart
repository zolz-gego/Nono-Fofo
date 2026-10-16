import 'dart:ui' show Rect;

/// Settings from `assets/content/games/writing.json`. Defaults here are only
/// used for keys missing from the file.
class WritingConfig {
  const WritingConfig({
    this.passAt = 0.85,
    this.messLimit = 0.6,
    this.warnAt = 0.5,
    this.halfwayCheerAt = 0.5,
    this.wipesToFail = 3,
    this.letterThicken = 0.012,
    this.chalkSizes = const [9, 15, 23],
    this.startSize = 1,
    this.demoStrokeSeconds = 1.1,
    this.background,
    this.board,
    this.boardSurface,
  });

  factory WritingConfig.fromJson(Map<String, dynamic> json) {
    const d = WritingConfig();
    final art = json['art'] as Map<String, dynamic>? ?? const {};
    final surface = art['boardSurface'] as Map<String, dynamic>?;
    return WritingConfig(
      passAt: (json['passAt'] as num?)?.toDouble() ?? d.passAt,
      messLimit: (json['messLimit'] as num?)?.toDouble() ?? d.messLimit,
      warnAt: (json['warnAt'] as num?)?.toDouble() ?? d.warnAt,
      halfwayCheerAt:
          (json['halfwayCheerAt'] as num?)?.toDouble() ?? d.halfwayCheerAt,
      wipesToFail: (json['wipesToFail'] as num?)?.toInt() ?? d.wipesToFail,
      letterThicken:
          (json['letterThicken'] as num?)?.toDouble() ?? d.letterThicken,
      chalkSizes:
          (json['chalkSizes'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          d.chalkSizes,
      startSize: (json['startSize'] as num?)?.toInt() ?? d.startSize,
      demoStrokeSeconds:
          (json['demoStrokeSeconds'] as num?)?.toDouble() ??
          d.demoStrokeSeconds,
      background: art['background'] as String?,
      board: art['board'] as String?,
      boardSurface: surface == null
          ? null
          : Rect.fromLTRB(
              (surface['left'] as num).toDouble(),
              (surface['top'] as num).toDouble(),
              (surface['right'] as num).toDouble(),
              (surface['bottom'] as num).toDouble(),
            ),
    );
  }

  /// Board passes when this much (0..1) of the letter has chalk.
  final double passAt;

  /// Mess meter full (= the other brother wipes the board) when the chalk
  /// outside the letter reaches this fraction of the letter's own size.
  final double messLimit;

  /// The other brother warns when the mess meter reaches this (0..1 of it).
  final double warnAt;

  /// The other brother cheers once when the letter is this full.
  final double halfwayCheerAt;

  /// Wipes in one level that make it "not passed".
  final int wipesToFail;

  /// How much thicker than the font the hollow letter is drawn, as a
  /// fraction of the board's height (bigger = easier to colour).
  final double letterThicken;

  /// Chalk thicknesses (thin, medium, thick) in board units (the board
  /// is 800 wide).
  final List<double> chalkSizes;

  /// Index into [chalkSizes] picked at the start.
  final int startSize;

  /// How long the demo takes to draw one stroke.
  final double demoStrokeSeconds;

  /// Grandpa's study picture (drawn in code when missing).
  final String? background;

  /// The chalkboard picture (drawn in code when missing).
  final String? board;

  /// Where the green is in [board], as fractions of the picture (printed
  /// by tools/games/process_writing.py).
  final Rect? boardSurface;
}
