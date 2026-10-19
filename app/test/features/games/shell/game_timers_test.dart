import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/shell/domain/game_timers.dart';

void main() {
  testWidgets('a timer waits out the pause and goes on from where it was', (
    tester,
  ) async {
    final timers = GameTimers();
    var fired = false;
    timers.later(const Duration(seconds: 2), () => fired = true);

    await tester.pump(const Duration(seconds: 1));
    timers.pause();
    await tester.pump(const Duration(seconds: 5));
    expect(fired, isFalse);

    timers.resume();
    await tester.pump(const Duration(milliseconds: 900));
    expect(fired, isFalse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(fired, isTrue);
  });

  testWidgets('a timer set while paused starts on resume', (tester) async {
    final timers = GameTimers()..pause();
    var fired = false;
    timers.later(const Duration(seconds: 1), () => fired = true);
    await tester.pump(const Duration(seconds: 3));
    expect(fired, isFalse);
    timers.resume();
    await tester.pump(const Duration(seconds: 1));
    expect(fired, isTrue);
  });

  testWidgets('cancelAll drops every pending timer', (tester) async {
    final timers = GameTimers();
    var fired = false;
    timers.later(const Duration(seconds: 1), () => fired = true);
    timers.cancelAll();
    await tester.pump(const Duration(seconds: 2));
    expect(fired, isFalse);
  });
}
