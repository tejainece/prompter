import 'dart:math';
import 'dart:async';

import 'line_mode.dart';
import 'package:prompter/src/tty/tty.dart';
import 'package:prompter/prompter.dart';

typedef BoolPromptTemplate = String Function(
    String label, String yesLabel, String noLabel);

typedef BoolContentTemplate = String Function(
    String yesLabel, String noLabel, bool value);

typedef BoolSuccessTemplate = String Function(
    String label, String yesLabel, String noLabel, bool value);

String boolPromptTemplate(String label, String yesLabel, String noLabel) =>
    '$label: ';

String boolContentTemplate(String yesLabel, String noLabel, bool value) =>
    value ? yesLabel : noLabel;

String boolSuccessTemplate(
    String label, String yesLabel, String noLabel, bool value) {
  return label + ': ' + (value ? yesLabel : noLabel) + '\n';
}

Future<bool> readYesOrNo(Tty tty, String name,
    {String question,
    String yes = 'y',
    String no = 'n',
    bool default_ = false,
    bool waitForEnter = false,
    BoolPromptTemplate promptTemplate = boolPromptTemplate,
    // BoolContentTemplate contentTemplate = boolContentTemplate,
    BoolSuccessTemplate successTemplate = boolSuccessTemplate}) async {
  question ??= name;
  bool value = default_;
  int yesChar = yes.runes.first;
  yes = String.fromCharCode(yesChar);
  int noChar = no.runes.first;
  no = String.fromCharCode(noChar);

  final mode = Mode(tty);
  mode.start();

  var renderer = TermBuffer(tty);

  final render = () async {
    String prompt = promptTemplate(question, yes, no);
    String content = value ? yes : no;

    renderer.setContent([prompt + content],
        cursor: Point<int>(prompt.runes.length + 1, 0));
    await renderer.render();
  };

  await render();

  final completer = Completer();

  final sub = tty.runes.listen((List<int> data) async {
    bool shouldRender = false;

    if (data.first == yesChar) {
      value = true;
      if (!waitForEnter) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      shouldRender = true;
    } else if (data.first == noChar) {
      value = false;
      if (!waitForEnter) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      shouldRender = true;
    } else if (data.first == asciiEnter) {
      if (!completer.isCompleted) completer.complete();
      return;
    }
    if (shouldRender) await render();
  });

  await completer.future;
  await sub.cancel();

  renderer.setContent([successTemplate(name, yes, no, value)]);
  await renderer.render();

  mode.stop();

  return value;
}
