import 'dart:async';
import 'dart:math';

import 'package:prompter/io.dart';
import 'package:prompter/src/tty/tty.dart';

import 'line_mode.dart';
import 'package:prompter/prompter.dart';

typedef PromptMultiLineTemplate = String Function(
    String label, List<String> value);

typedef MultiLineLineTemplate = String Function(
    int numLines, int lineNum, String line, bool hasCursor);

String promptMultiLineTemplate(String label, _) => '$label: ';

String multiLinePrefixTemplate(
    int numLines, int lineNum, String line, bool hasCursor) {
  var ln = lineNum.toString();
  return '\x1b[7m ' +
      (' ' * (numLines.toString().length - ln.length)) +
      ln +
      '\x1b[m';
}

String multiLineContentTemplate(
    int numLines, int lineNum, String line, bool hasCursor) {
  return line;
}

/// Reads multi-line text
Future<String> readMultiLineText(
  Tty tty, {
  String label = "",
  String default_ = "",
  Suggester suggester, // TODO
  PromptMultiLineTemplate promptTemplate = promptMultiLineTemplate,
  MultiLineLineTemplate linePrefixTemplate = multiLinePrefixTemplate,
  MultiLineLineTemplate lineTemplate = multiLineContentTemplate,
  SuccessTemplate<String> success = successTemplate,
}) async {
  final mode = Mode(tty);
  mode.start();

  var input = MultiLineInput(content: default_);
  var renderer = TermBuffer(tty);

  bool insertMode = false;

  final render = () async {
    final lines = input.lines;
    final pc = promptTemplate(label, lines);

    final pos = Point<int>(input.colNum, input.lineNum);
    int cursorCol = pos.x;

    for (int i = 0; i < lines.length; i++) {
      final prefix = linePrefixTemplate(lines.length, i + 1, lines[i], false);
      if (i == pos.y) cursorCol += prefix.runes.length;
      lines[i] = prefix + lineTemplate(lines.length, i + 1, lines[i], false);
    }

    renderer.setContent([
      pc,
      ...(lines.isNotEmpty ? lines : [' '])
    ], cursor: Point<int>(cursorCol, 1 + pos.y), insertMode: insertMode);

    await renderer.render();
  };

  await render();

  final completer = Completer();

  int upDownCol;

  final sub = tty.runes.listen((List<int> data) async {
    if (completer.isCompleted) return;

    bool shouldRender = false;
    bool isLineNav = false;

    final chars = String.fromCharCodes(data);
    if (chars.startsWith('\x1b[')) {
      final seq = chars.substring(2);
      if (seq == "D") {
        if (input.canMoveBackward) {
          input.moveBackward();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "C") {
        if (input.canMoveForward) {
          input.moveForward();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "H") {
        if (input.canMoveBackward) {
          input.moveToStartOfLine();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "F") {
        if (input.canMoveForward) {
          input.moveToEndOfLine();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq.endsWith('H')) {
        if (input.canMoveBackward) {
          input.moveToStart();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq.endsWith("F")) {
        if (input.canMoveForward) {
          input.moveToEnd();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "2~") {
        insertMode = !insertMode;
        shouldRender = true;
      } else if (seq == '3~') {
        if (input.canDel) {
          input.del();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "A") {
        if (input.canMoveUp) {
          if (upDownCol == null) upDownCol = input.colNum;
          input.moveUp(pos: upDownCol);
          isLineNav = true;
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (seq == "B") {
        if (input.canMoveDown) {
          if (upDownCol == null) upDownCol = input.colNum;
          input.moveDown(pos: upDownCol);
          isLineNav = true;
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else {
        // stdout.write(data);
      }
    } else if (data.first == asciiEscape) {
      if (data.length == 2) {
        final key = data.elementAt(1);
        if (key == asciif) {
          if (input.canMoveForward) {
            input.moveForwardWord();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else if (key == asciib) {
          if (input.canMoveBackward) {
            input.moveBackwardWord();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else if (key == asciie) {
          if (input.canMoveForward) {
            input.moveToEndOfWord();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else if (key == asciid) {
          // TODO remove line if it is empty
          input.deleteLine();
          shouldRender = true;
        } else if (key == asciiEnter) {
          shouldRender = true;
          if (!completer.isCompleted) completer.complete();
          return;
        }
      }
    } else if (data.first == asciiDel) {
      if (input.canBackspace) {
        input.backspace();
        shouldRender = true;
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiCtrlu) {
      if (input.canMoveBackward) {
        input.deleteToStartOfLine();
        shouldRender = true;
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiCtrlk) {
      if (input.canMoveForward) {
        input.deleteToEndOfLine();
        shouldRender = true;
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiCtrlb) {
      if (input.canMoveBackward) {
        input.deleteToStartOfWord();
        shouldRender = true;
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiCtrlf) {
      if (input.canMoveForward) {
        input.deleteToEndOfWord();
        shouldRender = true;
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiEnter) {
      input.newLine();
      shouldRender = true;
    } else {
      // stdout.write(data);
      // stdout.write(chars);
      shouldRender = true;
      if (!insertMode) {
        chars.runes.forEach(input.writeChar);
      } else {
        chars.runes.forEach(input.replaceChar);
      }
      // stdout.write(input.content.runes);
      // stdout.write(input.content);
    }

    if (shouldRender) {
      await render();
      if (!isLineNav) upDownCol = null;
    }
  });

  await completer.future;
  await sub.cancel();

  renderer.setContent([success(label, input.content)]);
  await renderer.render();

  mode.stop();

  return input.content;
}
