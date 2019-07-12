import 'package:meta/meta.dart';
import 'dart:async';
import 'package:prompter/prompter.dart';
import '../line_mode.dart';
import '../pager.dart';
import 'package:prompter/src/tty/tty.dart';

typedef SelectPromptTemplate = String Function(String label, String selected);

typedef SelectItemTemplate = String Function(
    int index, String option, bool selected);

String selectPromptTemplate(String label, _) => '$label: ';

String selectItemTemplate(int index, String option, bool selected) {
  if (selected) {
    return '\x1b[7m' + '> $option' + '\x1b[m';
  } else {
    return '  $option';
  }
}

Future<String> select(Tty tty, String name, List<String> options,
    {String question,
    int selected = 0,
    SelectPromptTemplate promptTemplate = selectPromptTemplate,
    SelectItemTemplate itemTemplate = selectItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  final index = await selectIndex(tty, name, options,
      question: question,
      selected: selected,
      promptTemplate: promptTemplate,
      itemTemplate: itemTemplate,
      success: success);
  return options[index];
}

Future<int> selectIndex(Tty tty, String name, List<String> options,
    {String question,
    int selected = 0,
    int itemsPerPage = 5,
    SelectPromptTemplate promptTemplate = selectPromptTemplate,
    SelectItemTemplate itemTemplate = selectItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  question ??= name;
  final pager = Pager(options, itemsPerPage: itemsPerPage);

  final mode = Mode(tty);
  mode.start();

  final buffer = TermBuffer(tty);

  final render = () async {
    final lines = <String>[];
    lines.add(promptTemplate(question, options[selected]));
    for (int i = pager.startIndexOfCurrentPage;
        i <= pager.lastIndexOfCurrentPage;
        i++) {
      String content = "";
      if (pager.needsPaging) {
        content += ' ';
        if (i == pager.startIndexOfCurrentPage) {
          if (pager.hasPreviousPage) {
            content += '\u25B2';
          } else {
            content += ' ';
          }
        } else if (i == pager.lastIndexOfCurrentPage) {
          if (pager.hasNextPage) {
            content += '\u25BC';
          } else {
            content += ' ';
          }
        } else {
          content += ' ';
        }
        content += ' ';
      }
      content += itemTemplate(i, options[i], selected == i);
      lines.add(content);
    }
    buffer.setContent(lines);
    await buffer.render();
  };

  await buffer.init();

  await render();

  final completer = Completer();

  final sub = tty.runes.listen((List<int> data) async {
    bool shouldRender = true;
    final chars = tty.encoding.decode(data);
    if (chars.startsWith('\x1b[')) {
      final seq = chars.substring(2);
      if (seq == "A") {
        if (selected > 0) {
          selected--;
        } else {
          selected = options.length - 1;
        }
        pager.moveToPageContainingIndex(selected);
      } else if (seq == "B") {
        if (selected < options.length - 1) {
          selected++;
        } else {
          selected = 0;
        }
        pager.moveToPageContainingIndex(selected);
      } else if (seq == "5~") {
        if (pager.hasPreviousPage) {
          pager.goToPreviousPage();
          selected = pager.lastIndexOfCurrentPage;
        } else {
          shouldRender = false;
          tty.ringBell();
        }
      } else if (seq == "6~") {
        if (pager.hasNextPage) {
          pager.goToNextPage();
          selected = pager.startIndexOfCurrentPage;
        } else {
          shouldRender = false;
          tty.ringBell();
        }
      } else {
        // stdout.write(data);
        shouldRender = false;
      }
    } else if (data.first == asciiEnter) {
      completer.complete();
      return;
    } else if (data.first == asciif || data.first == asciiF) {
      // TODO filter mode
    } else {
      shouldRender = false;
      // stdout.write(data);
    }
    if (shouldRender) await render();
  });

  await completer.future;
  await sub.cancel();

  {
    buffer.setContent([success(name, options[selected])]);
    await buffer.render();
  }

  mode.stop();

  return selected;
}
