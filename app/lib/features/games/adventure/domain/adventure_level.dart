/// Where a level takes place; decides its look, enemies and music.
enum AdventurePlace { nile, desert, alexandria }

/// One tile of the map grid.
enum Tile {
  air,
  ground,
  stone,
  brick,
  coinBlock,
  letterBlock,
  pageBlock,

  /// A block already hit (or a letter block whose letter was won).
  usedBlock;

  bool get solid => this != air;

  /// Blocks that react when hit from below.
  bool get bumpable =>
      this == brick ||
      this == coinBlock ||
      this == letterBlock ||
      this == pageBlock;
}

enum EnemyKind { duck, scorpion, crab, seagull }

enum PlatformKind { sideways, upDown, falling }

/// A grid position (column, row; row 0 is the top).
class Cell {
  const Cell(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);
}

class EnemySpawn {
  const EnemySpawn(this.kind, this.cell);

  final EnemyKind kind;
  final Cell cell;
}

class PlatformSpawn {
  const PlatformSpawn(this.kind, this.cell);

  final PlatformKind kind;
  final Cell cell;
}

/// One level, parsed from its text map in `adventure.json` (see the
/// legend there).
class AdventureLevel {
  AdventureLevel({
    required this.id,
    required this.place,
    required this.tiles,
    required this.start,
    required this.gate,
    required this.coins,
    required this.checkpoints,
    required this.enemies,
    required this.platforms,
    required this.letterBlocks,
  });

  factory AdventureLevel.fromJson(Map<String, dynamic> json) {
    final rows = [for (final r in json['rows'] as List) r as String];
    final width = rows.first.length;
    final tiles = <List<Tile>>[];
    Cell? start, gate;
    final coins = <Cell>[];
    final checkpoints = <Cell>[];
    final enemies = <EnemySpawn>[];
    final platforms = <PlatformSpawn>[];
    final letterBlocks = <Cell>[];
    for (final (r, row) in rows.indexed) {
      if (row.length != width) {
        throw FormatException(
          'Row $r of level ${json['id']} has the wrong '
          'length (${row.length}, expected $width)',
        );
      }
      final line = <Tile>[];
      for (var c = 0; c < width; c++) {
        final cell = Cell(c, r);
        final ch = row[c];
        line.add(switch (ch) {
          'G' => Tile.ground,
          'S' => Tile.stone,
          'B' => Tile.brick,
          '?' => Tile.coinBlock,
          'L' => Tile.letterBlock,
          'P' => Tile.pageBlock,
          _ => Tile.air,
        });
        switch (ch) {
          case 'L':
            letterBlocks.add(cell);
          case 'o':
            coins.add(cell);
          case '@':
            start = cell;
          case 'E':
            gate = cell;
          case 'K':
            checkpoints.add(cell);
          case 'd':
            enemies.add(EnemySpawn(EnemyKind.duck, cell));
          case 's':
            enemies.add(EnemySpawn(EnemyKind.scorpion, cell));
          case 'c':
            enemies.add(EnemySpawn(EnemyKind.crab, cell));
          case 'g':
            enemies.add(EnemySpawn(EnemyKind.seagull, cell));
          case 'm':
            platforms.add(PlatformSpawn(PlatformKind.sideways, cell));
          case 'v':
            platforms.add(PlatformSpawn(PlatformKind.upDown, cell));
          case 'f':
            platforms.add(PlatformSpawn(PlatformKind.falling, cell));
        }
      }
      tiles.add(line);
    }
    if (start == null || gate == null) {
      throw FormatException(
        'Level ${json['id']} needs a start (@) and a '
        'gate (E)',
      );
    }
    return AdventureLevel(
      id: json['id'] as String,
      place: AdventurePlace.values.byName(json['place'] as String),
      tiles: tiles,
      start: start,
      gate: gate,
      coins: coins,
      checkpoints: checkpoints,
      enemies: enemies,
      platforms: platforms,
      letterBlocks: letterBlocks..sort((a, b) => a.col.compareTo(b.col)),
    );
  }

  final String id;
  final AdventurePlace place;

  /// `tiles[row][col]`, as in the file (blocks hit during play are tracked
  /// by the game, not here).
  final List<List<Tile>> tiles;
  final Cell start;

  /// The letters gate; Grandpa's book stands just after it.
  final Cell gate;
  final List<Cell> coins;
  final List<Cell> checkpoints;
  final List<EnemySpawn> enemies;
  final List<PlatformSpawn> platforms;

  /// Letter blocks from left to right; the i-th hides the i-th letter.
  final List<Cell> letterBlocks;

  int get width => tiles.first.length;
  int get height => tiles.length;

  /// Every coin the level holds: floating coins and coin blocks.
  int get totalCoins =>
      coins.length +
      tiles.fold(
        0,
        (n, row) => n + row.where((t) => t == Tile.coinBlock).length,
      );
}
