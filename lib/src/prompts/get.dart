import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:prompter/src/validator.dart';

import 'line_mode.dart';
import 'package:prompter/prompter.dart';

abstract class Stringer<T> {
  String from(T value);

  T to(String value);
}

Future<T> get<T>(
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
  final mode = Mode();
  mode.start();

  final defaultStr = default_ != null ? stringer.from(default_) : '';

  var input = LineInput(content: defaultStr);
  var renderer = TermBuffer();

  final render = () {
    String contentStr = input.content;
    T content = stringer.to(contentStr);
    final error = validator(content);
    final pc = prompt(label, contentStr, error);
    final mc = main(label, contentStr, error);
    final pfc = postfix(label, contentStr, error);
    renderer.setContent([pc + mc + ' ' + pfc],
        cursor: Point<int>(pc.length + input.pos, 0));
    return error;
  };

  render();

  await renderer.start();

  bool insertMode = false;

  final completer = Completer();

  final sub = listen((List<int> data) async {
    bool shouldRender = true;

    final chars = systemEncoding.decode(data);
    if (chars.startsWith('\x1b[')) {
      final seq = chars.substring(2);
      if (seq == "D") {
        if (input.canMoveBackward) {
          input.moveBackward();
        } else {
          stdout.write("\x07");
        }
      } else if (seq == "C") {
        if (input.canMoveForward) {
          input.moveForward();
        } else {
          stdout.write("\x07");
        }
      } else if (seq == "H") {
        if (input.canMoveBackward) {
          input.moveToStart();
        } else {
          stdout.write("\x07");
        }
      } else if (seq == "F") {
        if (input.canMoveForward) {
          input.moveToEnd();
        } else {
          stdout.write("\x07");
        }
      } else if (seq == "2~") {
        insertMode = !insertMode;
      } else if (seq == '3~') {
        if (input.canDel) {
          input.del();
        } else {
          stdout.write("\x07");
        }
      } else {
        // stdout.write(data);
      }
    } else if (data.first == asciiDel) {
      if (input.canBackspace) {
        input.backspace();
      } else {
        stdout.write("\x07");
      }
    } else if (data.first == 10) {
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

  renderer.stop();

  renderer.setContent([success(label, input.content)]);
  renderer.render();

  mode.stop();

  return stringer.to(input.content);
}
