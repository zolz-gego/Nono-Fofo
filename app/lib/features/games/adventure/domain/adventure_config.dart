import 'adventure_level.dart';

/// How the hero moves, in tiles and seconds.
class AdventurePhysics {
  const AdventurePhysics({
    this.gravity = 55,
    this.jump = 20,
    this.runSpeed = 7.5,
    this.accel = 40,
    this.airAccel = 26,
    this.maxFall = 20,
    this.stompBounce = 12,
    this.hurtTime = 2,
  });

  factory AdventurePhysics.fromJson(Map<String, dynamic> json) {
    double n(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return AdventurePhysics(
      gravity: n('gravity', 55),
      jump: n('jump', 20),
      runSpeed: n('runSpeed', 7.5),
      accel: n('accel', 40),
      airAccel: n('airAccel', 26),
      maxFall: n('maxFall', 20),
      stompBounce: n('stompBounce', 12),
      hurtTime: n('hurtTime', 2),
    );
  }

  final double gravity;

  /// Jump speed; holding jump longer jumps higher.
  final double jump;
  final double runSpeed;
  final double accel;
  final double airAccel;
  final double maxFall;

  /// Upward speed after stomping an enemy.
  final double stompBounce;

  /// Blinking, can't-be-hit time after shrinking back to Fofo.
  final double hurtTime;
}

/// Settings from `assets/content/games/adventure.json`. Defaults here are
/// only used for keys missing from the file.
class AdventureConfig {
  const AdventureConfig({
    required this.levels,
    this.letters = 5,
    this.lives = 3,
    this.maxLives = 5,
    this.coinsPerLife = 30,
    this.stars = const [0.5, 0.9],
    this.pageCoins = 5,
    this.physics = const AdventurePhysics(),
    this.enemySpeeds = const {},
  });

  factory AdventureConfig.fromJson(Map<String, dynamic> json) =>
      AdventureConfig(
        letters: (json['letters'] as num?)?.toInt() ?? 5,
        lives: (json['lives'] as num?)?.toInt() ?? 3,
        maxLives: (json['maxLives'] as num?)?.toInt() ?? 5,
        coinsPerLife: (json['coinsPerLife'] as num?)?.toInt() ?? 30,
        stars: [
          for (final s in (json['stars'] as List?) ?? const [0.5, 0.9])
            (s as num).toDouble(),
        ],
        pageCoins: (json['pageCoins'] as num?)?.toInt() ?? 5,
        physics: AdventurePhysics.fromJson(
          (json['physics'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        enemySpeeds: {
          for (final e in ((json['enemies'] as Map?) ?? const {}).entries)
            EnemyKind.values.byName(e.key as String): (e.value as num)
                .toDouble(),
        },
        levels: [
          for (final l in (json['levels'] as List))
            AdventureLevel.fromJson((l as Map).cast<String, dynamic>()),
        ],
      );

  final List<AdventureLevel> levels;

  /// Letters hidden in each level (one per letter block).
  final int letters;
  final int lives;
  final int maxLives;

  /// Coins for one extra life.
  final int coinsPerLife;

  /// Share of the level's coins for 2 and 3 stars.
  final List<double> stars;

  /// Coins for touching Grandpa's page when already big.
  final int pageCoins;
  final AdventurePhysics physics;
  final Map<EnemyKind, double> enemySpeeds;

  double speedOf(EnemyKind kind) => enemySpeeds[kind] ?? 2;

  /// 1–3 stars for finishing with [coins] of [total].
  int starsFor(int coins, int total) {
    if (total <= 0) return 3;
    final share = coins / total;
    if (share >= stars[1]) return 3;
    if (share >= stars[0]) return 2;
    return 1;
  }
}
