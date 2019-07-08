import 'dart:io';
import 'dart:io' as io show stdout, stdin;
import 'dart:math';
import 'dart:async';
import 'dart:convert';

const asciiEscape = 27;
const asciiDel = 127;

/*
class LineRenderer {
  String _content = "";

  int _curPos = 0;

  Point<int> _start;

  LineRenderer([Point<int> start]) : _start = start;

  void setContent(String content, int cursorPos) {
    _content = content;
    _curPos = cursorPos;
  }

  Timer _timer;

  int _cursorTime = 0;

  void start() {
    stop();
    _cursorTime = 0;
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _cursorTime++;
      if (_cursorTime == 12) _cursorTime = 0;
      render();
    });
  }

  void stop() {
    if (_timer != null) {
      _timer.cancel();
    }
    _timer = null;
  }

  void render({bool showCursor = true}) async {
    stdout.write('\x1b[${_start.y};${_start.x}f');
    stdout.write('\x1b[2K\x1b[J');
    for (int i = 0; i < _content.runes.length; i++) {
      if (i == _curPos && _cursorTime > 2) {
        stdout.write("\u2588");
      } else {
        stdout.add(systemEncoding
            .encode(String.fromCharCode(_content.runes.elementAt(i))));
      }
    }
    if (_curPos == _content.length) {
      if (_cursorTime > 2) {
        stdout.write("\u2588");
      }
    }
  }
}

class MultilineRenderer {
  final List<LineRenderer> renderers;

  MultilineRenderer(this.renderers);

  void setup() {
    for (int i = 0; i < renderers.length - 1; i++) {
      stdout.write('\r\n');
    }
  }

  void render() {
    // Move up
    for (int i = 0; i < renderers.length; i++) {
      stdout.write('\x1b[A');
    }

    for (LineRenderer renderer in renderers) {
      stdout.write('\x1b[B');
      renderer.render(showCursor: false);
    }
  }

  void reset() {
    // Delete lines
    for (int i = 0; i < renderers.length - 1; i++) {
      stdout.write('\x1b[2K\x1b[A');
    }
  }
}
 */

class TermBuffer {
  List<String> _lines = [];

  Point<int> _curPos;

  Point<int> _startingPos;

  XTermOut xterm = XTermOut();

  Timer _timer;

  TermBuffer();

  void setContent(List<String> lines, {Point<int> cursor}) {
    _lines = lines.toList();
    _curPos = cursor;
  }

  int _milliseconds = 0;

  int get _seconds => _milliseconds ~/ 1000;

  Future<void> start() async {
    _startingPos = await cursorPosition;
    stop();
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      _milliseconds += 100;
      render();
    });
  }

  void stop() {
    if (_timer != null) {
      _timer.cancel();
    }
    _milliseconds = 0;
    _timer = null;
  }

  void render() {
    xterm.moveTo(_startingPos);
    xterm.moveToColStart();
    xterm.clearCurrentLine();
    xterm.eraseLinesBelow();

    for (int lineNum = 0; lineNum < _lines.length; lineNum++) {
      String line = _lines[lineNum];
      if (_curPos == null || lineNum != _curPos.y) {
        xterm.write(line);
      } else {
        bool showCursor = _seconds.isEven;
        for (int colNum = 0; colNum < line.runes.length; colNum++) {
          if (colNum == _curPos.x && showCursor) {
            stdout.write("\u2588");
          } else {
            stdout.write(String.fromCharCode(line.runes.elementAt(colNum)));
          }
        }
      }
      if (lineNum != _lines.length - 1) xterm.write('\n\r');
    }
  }
}

class XTermOut {
  final StreamSink<List<int>> stdout;

  final Encoding encoding;

  XTermOut({Encoding encoding, StreamSink<List<int>> stdout})
      : stdout = stdout ?? io.stdout,
        encoding = encoding ?? systemEncoding;

  /// Moves the terminal cursor to given [position]
  void moveTo(Point<int> position) {
    write('\x1b[${position.y};${position.x}f');
  }

  void moveToColStart() {
    write('\r');
  }

  void clearCurrentLine() {
    write('\x1b[J');
  }

  void eraseLinesBelow() {
    write('\x1b[J');
  }

  void ringBell() {
    write('\x07');
  }

  void write(String data) {
    stdout.add(encoding.encode(data));
  }
}

Point<int> parseCursorPosition(String input) {
  final match = RegExp('^([0-9]+);([0-9]+)R\$').matchAsPrefix(input);
  if (match == null) return null;
  return Point<int>(int.parse(match.group(2)), int.parse(match.group(1)));
}

Future<Point<int>> get cursorPosition async {
  final completer = Completer<Point<int>>();
  final sub = listen((data) {
    final chars = systemEncoding.decode(data);
    if (!chars.startsWith('\x1b[')) return;
    final seq = chars.substring(2);
    final pos = parseCursorPosition(seq);
    if (pos != null) completer.complete(pos);
  });
  stdout.write('\x1b[6n');
  final ret = await completer.future;
  await sub.cancel();
  return ret;
}

Stream<TimedBytes> _stdin;

class TimedBytes {
  final DateTime time;

  final List<int> data;

  TimedBytes(this.time, this.data);
}

Stream<TimedBytes> get stdinBC {
  _stdin ??= io.stdin.map((data) {
    return TimedBytes(DateTime.now().toUtc(), data);
  }).asBroadcastStream();
  return _stdin;
}

StreamSubscription<List<int>> listen(void onData(List<int> event)) {
  final now = DateTime.now().toUtc();
  return stdinBC
      .where((td) => td.time.isAfter(now))
      .map((td) => td.data)
      .listen(onData);
}
