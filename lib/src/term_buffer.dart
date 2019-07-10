import 'dart:math';
import 'dart:async';
import 'dart:convert';

import 'package:prompter/src/tty/tty.dart';

const asciiEscape = 27;
const asciiDel = 127;
const asciiEnter = 10;
const asciiF = 70;
const asciif = 102;
const asciiSpace = 32;

class TermBuffer {
  List<String> _lines = [];

  Point<int> _curPos; // TODO

  // Point<int> _startingPos;

  final Tty tty;

  TermBuffer(this.tty);

  void setContent(List<String> lines, {Point<int> cursor}) {
    _lines = lines.toList();
    _curPos = cursor;
  }

  Completer _rendering;

  Future<void> init() async {
    // _startingPos = await cursorPosition;
  }

  List<int> _lineLengths = [];

  Future<void> render() async {
    while (_rendering != null) {
      await _rendering.future;
    }
    _rendering = Completer();

    final size = await tty.size;

    var startPos = await tty.cursorPosition;

    int prevHeight = 0;
    for(int h in _lineLengths) {
      prevHeight++;
      prevHeight += (h - 1) ~/ size.x;
    }
    _lineLengths.clear();

    if (prevHeight != 0) {
      tty.moveTo(Point<int>(1, startPos.y - prevHeight + 1));
      tty.moveToColStart();
      tty.eraseLinesBelow();
    }
    // tty.write("${startPos} ${prevHeight}");

    for (int lineNum = 0; lineNum < _lines.length; lineNum++) {
      tty.moveToColStart();

      // pos = await tty.cursorPosition;
      // tty.write(pos.toString());

      String line = _lines[lineNum];

      _lineLengths.add(line.runes.length);

      for (int colNum = 0; colNum < line.runes.length; colNum++) {
        tty.write(String.fromCharCode(line.runes.elementAt(colNum)));
      }

      tty.write(line.runes.length.toString());

      if (lineNum != _lines.length - 1) {
        tty.write('\n');
      }
    }

    prevHeight = 0;
    for(int h in _lineLengths) {
      prevHeight++;
      prevHeight += (h - 1) ~/ size.x;
    }

    _rendering.complete();
    _rendering = null;
  }
}
