import 'dart:async';
import 'dart:convert';
import 'dart:math';

typedef Listener<T> = StreamSubscription<T> Function(void Function(T data));

abstract class Tty {
  StreamSink<List<int>> get out;

  StreamSubscription<List<int>> listen(
      Future<void> Function(List<int> data) onData);

  Encoding get encoding;

  bool echoMode;

  bool lineMode;

  /// Moves the terminal cursor to given [position]
  void moveTo(Point<int> position) {
    write('\x1b[${position.y};${position.x}f');
  }

  void moveToColStart() {
    write('\r');
  }

  void clearCurrentLine() {
    write('\x1b[2K');
  }

  void eraseLinesBelow() {
    write('\x1b[J');
  }

  void ringBell() {
    write('\x07');
  }

  void moveUp() {
    write('\x1b[A');
  }

  void moveDown() {
    write('\x1b[B');
  }

  void write(String data) {
    out.add(encoding.encode(data));
  }

  void reportCursorPosition() {
    write('\x1b[6n');
  }

  void saveCursorPosition() {
    write('\x1b[s');
  }

  void restoreCursorPosition() {
    write('\x1b[u');
  }

  void moveToBottomRight() {
    moveTo(Point<int>(999, 999));
  }

  void showCursor() {
    write("\x1b[?25h");
  }

  void hideCursor() {
    write("\x1b[?25l");
  }

  void disableWrap() {
    write('\x1b[?7l');
  }

  void enableWrap() {
    write('\x1b[?7h');
  }

  Future<Point<int>> get cursorPosition async {
    final completer = Completer<Point<int>>();
    final sub = listen((data) {
      final chars = encoding.decode(data);
      if (!chars.startsWith('\x1b[')) return;
      final seq = chars.substring(2);
      final pos = parseCursorPosition(seq);
      if (pos != null) completer.complete(pos);
    });
    reportCursorPosition();
    final ret = await completer.future;
    await sub.cancel();
    return ret;
  }

  Future<Point<int>> get size async {
    final completer = Completer<Point<int>>();
    final sub = listen((data) {
      final chars = encoding.decode(data);
      if (!chars.startsWith('\x1b[')) return;
      final seq = chars.substring(2);
      final pos = parseCursorPosition(seq);
      if (pos != null) completer.complete(pos);
    });
    saveCursorPosition();
    moveToBottomRight();
    reportCursorPosition();
    final ret = await completer.future;
    restoreCursorPosition();
    await sub.cancel();
    return ret;
  }
}

Point<int> parseCursorPosition(String input) {
  final match = RegExp('^([0-9]+);([0-9]+)R\$').matchAsPrefix(input);
  if (match == null) return null;
  return Point<int>(int.parse(match.group(2)), int.parse(match.group(1)));
}
