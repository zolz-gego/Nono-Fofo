import 'dart:ui' show Color, Rect;

/// Settings from `assets/content/games/monastery.json`. Defaults here are
/// only used for keys missing from the file.
class MonasteryConfig {
  const MonasteryConfig({
    this.letterCounts = const [5, 6, 7, 8, 9, 10],
    this.phoneLetters = 5,
    this.smallScreenWidth = 600,
    this.heroRun = const Duration(milliseconds: 650),
    this.nameBubble = const Duration(milliseconds: 1500),
    this.hintGlow = const Duration(milliseconds: 2600),
    this.tapRadius = 1,
    this.minSpotGap = 0.1,
    this.maxRotation = 25,
    this.letterColors = const [],
    this.letterOpacity = 0.92,
    this.showSpots = false,
    this.scene = const MonasteryScene(),
  });

  factory MonasteryConfig.fromJson(Map<String, dynamic> json) {
    const d = MonasteryConfig();
    Duration? ms(String key) {
      final v = json[key] as num?;
      return v == null ? null : Duration(milliseconds: v.toInt());
    }

    double? num_(String key) => (json[key] as num?)?.toDouble();
    final scene = json['scene'] as Map<String, dynamic>?;

    return MonasteryConfig(
      letterCounts:
          (json['letterCounts'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          d.letterCounts,
      phoneLetters: (json['phoneLetters'] as num?)?.toInt() ?? d.phoneLetters,
      smallScreenWidth: num_('smallScreenWidth') ?? d.smallScreenWidth,
      heroRun: ms('heroRunMs') ?? d.heroRun,
      nameBubble: ms('nameBubbleMs') ?? d.nameBubble,
      hintGlow: ms('hintGlowMs') ?? d.hintGlow,
      tapRadius: num_('tapRadius') ?? d.tapRadius,
      minSpotGap: num_('minSpotGap') ?? d.minSpotGap,
      maxRotation: num_('maxRotation') ?? d.maxRotation,
      letterColors:
          (json['letterColors'] as List?)
              ?.map((e) => _hex(e as String))
              .toList() ??
          d.letterColors,
      letterOpacity: num_('letterOpacity') ?? d.letterOpacity,
      showSpots: json['showSpots'] as bool? ?? d.showSpots,
      scene: scene == null ? d.scene : MonasteryScene.fromJson(scene),
    );
  }

  /// The levels: how many letters hide.
  final List<int> letterCounts;

  /// Phones skip the picker and always hide this many.
  final int phoneLetters;

  /// Screens whose shortest side is under this are "small": no brothers,
  /// and [phoneLetters] letters only.
  final double smallScreenWidth;

  /// Time for the brother to reach a found letter.
  final Duration heroRun;

  /// How long the letter's name bubble stays.
  final Duration nameBubble;

  /// How long a hint's glow pulses.
  final Duration hintGlow;

  /// How forgiving a tap is (1 = about the letter's size).
  final double tapRadius;

  /// Two letters never hide closer than this (in scene heights).
  final double minSpotGap;

  /// Letters lean up to this many degrees either way.
  final double maxRotation;

  /// Muted colours that blend with the room; each letter gets one.
  final List<Color> letterColors;
  final double letterOpacity;

  /// Draws every hiding spot, to line spots up with new art.
  final bool showSpots;
  final MonasteryScene scene;

  bool isSmallScreen(double shortestSide) => shortestSide < smallScreenWidth;

  static Color _hex(String s) =>
      Color(int.parse(s.replaceFirst('#', ''), radix: 16) | 0xFF000000);
}

/// The room: a background, the objects in front of the letters, and the
/// spots letters can hide at. All positions are fractions of the scene
/// (x of its width, y of its height).
class MonasteryScene {
  const MonasteryScene({
    this.aspect = 16 / 9,
    this.background,
    this.objects = const [],
    this.spots = const [],
  });

  factory MonasteryScene.fromJson(Map<String, dynamic> json) => MonasteryScene(
    aspect: (json['aspect'] as num?)?.toDouble() ?? 16 / 9,
    background: json['background'] as String?,
    objects: [
      for (final o in json['objects'] as List? ?? const [])
        SceneObject.fromJson(o as Map<String, dynamic>),
    ],
    spots: [
      for (final s in json['spots'] as List? ?? const [])
        HidingSpot.fromJson(s as Map<String, dynamic>),
    ],
  );

  /// Width / height of the scene picture.
  final double aspect;

  /// The empty room picture (drawn in code when null).
  final String? background;
  final List<SceneObject> objects;
  final List<HidingSpot> spots;
}

/// Something standing in front of the letters.
class SceneObject {
  const SceneObject({
    required this.id,
    required this.shape,
    required this.rect,
    this.image,
  });

  factory SceneObject.fromJson(Map<String, dynamic> json) {
    final r = [for (final v in json['rect'] as List) (v as num).toDouble()];
    return SceneObject(
      id: json['id'] as String,
      shape: json['shape'] as String? ?? json['id'] as String,
      rect: Rect.fromLTWH(r[0], r[1], r[2], r[3]),
      image: json['image'] as String?,
    );
  }

  final String id;

  /// What to draw in code until there is an [image].
  final String shape;

  /// Where it stands, in scene fractions.
  final Rect rect;

  /// A transparent cut-out picture.
  final String? image;
}

/// A place a letter can hide: its centre and its size (a fraction of the
/// scene height).
class HidingSpot {
  const HidingSpot({required this.x, required this.y, this.size = 0.08});

  factory HidingSpot.fromJson(Map<String, dynamic> json) => HidingSpot(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    size: (json['size'] as num?)?.toDouble() ?? 0.08,
  );

  final double x;
  final double y;
  final double size;
}
