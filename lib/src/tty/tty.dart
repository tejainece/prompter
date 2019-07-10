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

  void insertLines(int count) {
    write('\x1b[${count}L');
  }

  void clearCurrentLine() {
    write('\x1b[2K');
  }

  void eraseLinesBelow() {
    write('\x1b[J');
  }

  void clearScreen() {
    write('\x1b[2J');
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
    await Future.delayed(Duration(milliseconds: 1));
    final sub = listen((inp) {
      for (final data in parseStdin(encoding.decode(inp).runes.toList())) {
        final chars = String.fromCharCodes(data);
        if (!chars.startsWith('\x1b[')) return;
        final seq = chars.substring(2);
        final pos = parseCursorPosition(seq);
        if (pos != null) {
          completer.complete(pos);
          return;
        }
      }
    });
    Point<int> ret;
    do {
      reportCursorPosition();
      try {
        ret = await completer.future.timeout(Duration(milliseconds: 200));
        break;
      } catch (e) {}
    } while (true);
    await sub.cancel();
    return ret;
  }

  // FutureOr<Point<int>> get size;

  FutureOr<Point<int>> get size async {
    final completer = Completer<Point<int>>();
    await Future.delayed(Duration(milliseconds: 1));
    final sub = listen((inp) {
      for (final data in parseStdin(encoding.decode(inp).runes.toList())) {
        final chars = String.fromCharCodes(data);
        if (!chars.startsWith('\x1b[')) return;
        final seq = chars.substring(2);
        final pos = parseCursorPosition(seq);
        if (pos != null) {
          completer.complete(pos);
          return;
        }
      }
    });
    saveCursorPosition();
    moveToBottomRight();
    reportCursorPosition();
    Point<int> ret;
    do {
      reportCursorPosition();
      try {
        ret = await completer.future.timeout(Duration(milliseconds: 200));
        break;
      } catch (e) {}
    } while (true);
    restoreCursorPosition();
    await sub.cancel();
    return ret;
  }
}

final cursorPositionRegExp = RegExp('^([0-9]+);([0-9]+)R');

bool isCursorPosition(String input) =>
    cursorPositionRegExp.matchAsPrefix(input) != null;

Point<int> parseCursorPosition(String input) {
  final match = cursorPositionRegExp.matchAsPrefix(input);
  if (match == null) return null;
  return Point<int>(int.parse(match.group(2)), int.parse(match.group(1)));
}

const asciiEscape = 27;
const asciiDel = 127;
const asciiEnter = 10;
const asciiA = 65;
const asciiB = 66;
const asciiC = 67;
const asciiD = 68;
const asciiE = 69;
const asciiF = 70;
const asciiZ = 90;
const asciif = 102;
const ascii0 = 48;
const ascii9 = 57;
const asciiSpace = 32;
const asciiTilde = 126;
const asciiLeftSquareBracket = 91;

const asciiCtrlk = 11;
const asciiCtrlu = 21;

List<int> parseDigits(Iterable<int> data) {
  final ret = <int>[];

  for (int d in data) {
    if (d < ascii0 && d > ascii9) break;
    ret.add(d);
  }

  return ret;
}

Iterable<int> _parseStdinControlSequence(Iterable<int> startData) {
  var data = startData.skip(0);

  if (data.length == 1) return startData;

  data = data.skip(1);

  if (data.first != asciiLeftSquareBracket) return [startData.first];

  data = data.skip(1);

  if (data.isEmpty) return data;

  final ps = parseDigits(data);

  data = data.skip(ps.length);

  if (data.isEmpty) return startData;

  final d3 = data.first;
  if (d3 >= asciiA && d3 <= asciiZ) {
    return [asciiEscape, asciiLeftSquareBracket, ...ps, d3];
  } else if (d3 == asciiTilde) {
    return [asciiEscape, asciiLeftSquareBracket, ...ps, d3];
  }
  // TODO mouse stuff

  throw UnsupportedError("Unsupported control sequence!");
}

List<List<int>> parseStdin(List<int> data) {
  final ret = <List<int>>[];

  for (int i = 0; i < data.length; i++) {
    if (data[i] != asciiEscape) {
      ret.add([data[i]]);
      continue;
    }
    final next = _parseStdinControlSequence(data.skip(i));
    i += next.length;
    ret.add(next.toList());
  }

  return ret;
}
