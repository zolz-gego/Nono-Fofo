import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

/// One-shot timers a game schedules (a computer's move, a card turning
/// back) that stop counting while the game is paused and go on from where
/// they were on resume.
class GameTimers {
  final Set<_Pending> _pending = {};
  bool _paused = false;

  /// Runs [f] after [d] of play time.
  void later(Duration d, VoidCallback f) {
    final p = _Pending(d, f);
    _pending.add(p);
    if (!_paused) _run(p);
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    for (final p in _pending) {
      p.timer?.cancel();
      p.timer = null;
      p.left -= p.watch.elapsed;
      p.watch
        ..stop()
        ..reset();
    }
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    for (final p in [..._pending]) {
      _run(p);
    }
  }

  void cancelAll() {
    for (final p in _pending) {
      p.timer?.cancel();
    }
    _pending.clear();
  }

  void _run(_Pending p) {
    p.watch.start();
    p.timer = Timer(p.left.isNegative ? Duration.zero : p.left, () {
      _pending.remove(p);
      p.f();
    });
  }
}

class _Pending {
  _Pending(this.left, this.f);

  Duration left;
  final VoidCallback f;
  final Stopwatch watch = clock.stopwatch();
  Timer? timer;
}
