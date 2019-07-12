import 'dart:async';
import 'dart:convert';
import 'dart:math';

typedef Listener<T> = StreamSubscription<T> Function(void Function(T data));

abstract class Tty {
  StreamSink<List<int>> get out;

  Stream<List<int>> get bytes;

  Stream<List<int>> get runes {
    List<int> pending;
    return bytes.transform<List<int>>(StreamTransformer.fromHandlers(
        handleData: (List<int> input, EventSink<List<int>> sink) {
      List<int> send;
      if (pending != null) {
        send = pending.toList()..addAll(input);
      } else {
        send = input;
      }

      final runes = parseStdin(encoding.decode(send).runes.toList());
      if (runes.value.isNotEmpty) {
        pending = runes.value;
      } else {
        pending = null;
      }
      for (final r in runes.key) {
        sink.add(r);
      }
    }));
  }

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

  void writeRune(int data) {
    write(String.fromCharCode(data));
  }

  void writeRunes(Iterable<int> data) {
    write(String.fromCharCodes(data));
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
    await Future.delayed(Duration(milliseconds: 5));
    final sub = runes.listen((data) {
      if (completer.isCompleted) return;
      final chars = String.fromCharCodes(data);
      if (!chars.startsWith('\x1b[')) return;
      final seq = chars.substring(2);
      final pos = parseCursorPosition(seq);
      if (pos != null) {
        if (!completer.isCompleted) completer.complete(pos);
        return;
      }
    });
    Point<int> ret;
    reportCursorPosition();
    ret = await completer.future.timeout(Duration(milliseconds: 200));
    /*
    do {
      reportCursorPosition();
      try {
        ret = await completer.future.timeout(Duration(milliseconds: 200));
        break;
      } catch (e) {}
    } while (true);
     */
    await sub.cancel();
    return ret;
  }

  FutureOr<Point<int>> get size async {
    final completer = Completer<Point<int>>();
    await Future.delayed(Duration(milliseconds: 5));
    final sub = runes.listen((data) {
      if (completer.isCompleted) return;
      final chars = String.fromCharCodes(data);
      if (!chars.startsWith('\x1b[')) return;
      final seq = chars.substring(2);
      final pos = parseCursorPosition(seq);
      if (pos != null) {
        if (!completer.isCompleted) completer.complete(pos);
        return;
      }
    });
    saveCursorPosition();
    moveToBottomRight();
    reportCursorPosition();
    Point<int> ret;

    reportCursorPosition();
    ret = await completer.future.timeout(Duration(milliseconds: 200));

    /*
    do {
      reportCursorPosition();
      try {
        ret = await completer.future.timeout(Duration(milliseconds: 200));
        break;
      } catch (e) {}
    } while (true);
     */
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
const asciia = 97;
const asciib = 98;
const asciid = 100;
const asciie = 101;
const asciif = 102;
const asciis = 115;
const asciiz = 122;
const ascii0 = 48;
const ascii9 = 57;
const asciiSpace = 32;
const asciiTilde = 126;
const asciiSemicolon = 59;
const asciiLeftSquareBracket = 91;

const asciiCtrlb = 2;
const asciiCtrlf = 6;
const asciiCtrlk = 11;
const asciiCtrlu = 21;

List<int> parseDigits(Iterable<int> data) {
  final ret = <int>[];

  for (int d in data) {
    if (d < ascii0 || d > ascii9) break;
    ret.add(d);
  }

  return ret;
}

MapEntry<Iterable<int>, bool> _parseStdinControlSequence(
    Iterable<int> startData) {
  final ret = <int>[];

  ret.add(asciiEscape);
  var data = startData.skip(0);
  data = data.skip(1);

  if (data.isEmpty) return MapEntry(ret, false);

  if (data.first != asciiLeftSquareBracket) {
    return MapEntry(startData.take(2), true);
  }
  ret.add(asciiLeftSquareBracket);
  data = data.skip(1);
  if (data.isEmpty) return MapEntry(ret, false);

  var temp = parseDigits(data);
  ret.addAll(temp);
  data = data.skip(temp.length);
  if (data.isEmpty) return MapEntry(ret, false);

  while (data.first == asciiSemicolon) {
    ret.add(asciiSemicolon);
    data = data.skip(1);
    if (data.isEmpty) return MapEntry(ret, false);

    temp = parseDigits(data);
    ret.addAll(temp);
    data = data.skip(temp.length);
    if (data.isEmpty) return MapEntry(ret, false);
  }

  final d3 = data.first;
  if (d3 >= asciiA && d3 <= asciiZ) {
    ret.add(d3);
    return MapEntry(ret, true);
  } else if (d3 == asciiTilde) {
    ret.add(d3);
    return MapEntry(ret, true);
  }
  // TODO mouse stuff

  throw UnsupportedError("Unsupported control sequence $startData!");
}

MapEntry<List<List<int>>, List<int>> parseStdin(List<int> data) {
  final parsed = <List<int>>[];
  final pending = <int>[];

  for (int i = 0; i < data.length; i++) {
    if (data[i] != asciiEscape) {
      parsed.add([data[i]]);
      continue;
    }

    final next = _parseStdinControlSequence(data.skip(i));

    if (!next.value) {
      pending.addAll(next.key);
      break;
    }

    parsed.add(next.key.toList());
    i += next.key.length - 1;
  }

  final ret = MapEntry(parsed, pending);

  return ret;
}
