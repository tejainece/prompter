import 'dart:math';
import 'dart:async';
import 'package:prompter/src/tty/tty.dart';
import 'package:prompter/src/validator.dart';

import 'line_mode.dart';
import 'package:prompter/prompter.dart';

abstract class Stringer<T> {
  String from(T value);

  T to(String value);
}

Future<T> get<T>(Tty tty,
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
        cursor: Point<int>(pc.length + input.pos, 0));
    await renderer.render();
    return error;
  };

  await render();

  await renderer.init();

  bool insertMode = false;

  final completer = Completer();

  final sub = tty.listen((List<int> data) async {
    bool shouldRender = true;

    final chars = tty.encoding.decode(data);
    if (chars.startsWith('\x1b[')) {
      final seq = chars.substring(2);
      if (seq == "D") {
        if (input.canMoveBackward) {
          input.moveBackward();
        } else {
          tty.ringBell();
        }
      } else if (seq == "C") {
        if (input.canMoveForward) {
          input.moveForward();
        } else {
          tty.ringBell();
        }
      } else if (seq == "H") {
        if (input.canMoveBackward) {
          input.moveToStart();
        } else {
          tty.ringBell();
        }
      } else if (seq == "F") {
        if (input.canMoveForward) {
          input.moveToEnd();
        } else {
          tty.ringBell();
        }
      } else if (seq == "2~") {
        insertMode = !insertMode;
      } else if (seq == '3~') {
        if (input.canDel) {
          input.del();
        } else {
          tty.ringBell();
        }
      } else {
        // stdout.write(data);
        shouldRender = false;
      }
    } else if (data.first == asciiDel) {
      if (input.canBackspace) {
        input.backspace();
      } else {
        tty.ringBell();
      }
    } else if (data.first == asciiEnter) {
      final error = render();
      if (error == null) {
        completer.complete();
        return;
      }
    } else {
      // stdout.write(data);
      // stdout.write(chars);
      if (!insertMode) {
        chars.runes.forEach(input.writeChar);
      } else {
        chars.runes.forEach(input.replaceChar);
      }
      // stdout.write(input.content.runes);
      // stdout.write(input.content);
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
