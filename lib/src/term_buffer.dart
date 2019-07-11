import 'dart:math';
import 'dart:async';

import 'package:prompter/src/tty/tty.dart';

class TermBuffer {
  List<String> _lines = [];

  Point<int> _curPos; // TODO

  final Tty tty;

  TermBuffer(this.tty);

  void setContent(List<String> lines, {Point<int> cursor}) {
    _lines = lines.toList();
    _curPos = cursor;
  }

  Point<int> _startPos;

  Point<int> _oldSize;

  Completer _rendering;

  Future<void> init() async {
    // _startingPos = await cursorPosition;
  }

  Future<void> render() async {
    while (_rendering != null) {
      final future = _rendering.future;
      await future;
    }
    _rendering = Completer();

    if (_startPos == null) {
      _startPos = await tty.cursorPosition;
    }

    final size = await tty.size;

    if (_oldSize == null) _oldSize = size;

    if (_oldSize != size) {
      tty.clearScreen();
      _startPos = Point<int>(1, 1);
      _oldSize = size;
    } else if (_startPos.y == size.y) {
      tty.moveTo(Point<int>(1, _startPos.y));
      tty.clearCurrentLine();
      tty.eraseLinesBelow();

      for (int i = 0; i < size.y - 1; i++) {
        tty.write('\n');
      }

      _startPos = Point<int>(1, 1);
    }

    await _write();

    var pos = await tty.cursorPosition;

    if (pos.y == size.y) {
      tty.moveTo(Point<int>(1, _startPos.y));
      tty.clearCurrentLine();
      tty.eraseLinesBelow();

      for (int i = 0; i < size.y - 1; i++) {
        tty.write('\n');
      }

      _startPos = Point<int>(1, 1);
      await _write();
    }

    _rendering.complete();
    _rendering = null;
  }

  void _write() async {
    tty.moveTo(Point<int>(1, _startPos.y));
    tty.clearCurrentLine();
    tty.eraseLinesBelow();
    // tty.write("${startPos} ${prevHeight}");

    Point<int> showCursorAt;

    for (int lineNum = 0; lineNum < _lines.length; lineNum++) {
      tty.moveToColStart();

      // pos = await tty.cursorPosition;
      // tty.write(pos.toString());

      String line = _lines[lineNum];

      if (_curPos == null || _curPos.y != lineNum) {
        tty.write(line);
      } else {
        tty.write(line.substring(0, _curPos.x));
        tty.write('\u2588');
        tty.write(line.substring(_curPos.x + 1));
      }

      if (lineNum != _lines.length - 1) {
        tty.write('\n');
      }
    }

    if (showCursorAt != null) {
      tty.moveTo(showCursorAt);
      tty.showCursor();
    } else {
      tty.hideCursor();
    }
  }
}
