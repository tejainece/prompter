import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:prompter/src/tty/tty.dart';
import 'package:prompter/src/validator.dart';

import 'line_mode.dart';
import 'package:prompter/prompter.dart';

abstract class Stringer<T> {
  String from(T value);

  T to(String value);
}

Future<T> get<T>(
  Tty tty,
  Stringer<T> stringer, {
  String label = "",
  T default_,
  Validator<T> validator = noOpValidator,
  Suggester suggester, // TODO
  LineTemplate<String> prompt = promptLineTemplate,
  LineTemplate<String> main = mainLineTemplate,
  LineTemplate<String> postfix = noOpTemplate,
  SuccessTemplate<String> success = successTemplate,
}) async {
  final defaultStr = default_ != null ? stringer.from(default_) : '';

  final mode = Mode(tty);
  mode.start();

  var input = LineInput(content: defaultStr);
  var renderer = TermBuffer(tty);

  final render = () async {
    String contentStr = input.content;
    T content = stringer.to(contentStr);
    final error = validator(content);
    final pc = prompt(label, contentStr, error);
    final mc = main(label, contentStr, error);
    final pfc = postfix(label, contentStr, error);
    renderer.setContent([pc + mc + ' ' + pfc],
        cursor: Point<int>(pc.runes.length + input.pos, 0));
    await renderer.render();
    return error;
  };

  await render();

  await renderer.init();

  bool insertMode = false;

  final completer = Completer();

  final sub = tty.listen((List<int> inp) async {
    if(completer.isCompleted) return;

    bool shouldRender = false;

    final dataList = parseStdin(tty.encoding.decode(inp).runes.toList());
    for (final data in dataList) {
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
            input.moveToStart();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else if (seq == "F") {
          if (input.canMoveForward) {
            input.moveToEnd();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else if (seq == "2~") {
          insertMode = !insertMode;
        } else if (seq == '3~') {
          if (input.canDel) {
            input.del();
            shouldRender = true;
          } else {
            tty.ringBell();
          }
        } else {
          // stdout.write(data);
        }
      } else if(data.first == asciiEscape) {
        if(data.length == 2) {
          final key = data.elementAt(1);
          if(key == asciif) {
            input.moveForwardWord();
            shouldRender = true;
          } else if(key == asciib) {
            input.moveToStartWord();
            shouldRender = true;
          } else if(key == asciie) {
            input.moveToEndWord();
            shouldRender = true;
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
          input.deleteToStart();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (data.first == asciiCtrlk) {
        if (input.canMoveForward) {
          input.deleteToEnd();
          shouldRender = true;
        } else {
          tty.ringBell();
        }
      } else if (data.first == asciiEnter) {
        final error = await render();
        if (error == null) {
          if(!completer.isCompleted) completer.complete();
          return;
        }
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
    }

    if (shouldRender) await render();
  });

  await completer.future;
  await sub.cancel();

  renderer.setContent([success(label, input.content)]);
  await renderer.render();

  mode.stop();

  return stringer.to(input.content);
}
