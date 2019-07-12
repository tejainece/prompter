import 'package:meta/meta.dart';
import 'dart:async';
import 'package:prompter/prompter.dart';
import 'package:prompter/src/tty/tty.dart';
import '../line_mode.dart';
import '../pager.dart';

typedef MultiSelectPromptTemplate = String Function(
    String label, List<String> selected);

typedef MultiSelectItemTemplate = String Function(
    int index, String option, bool selected, bool active);

String multiSelectPromptTemplate(String label, _) => '$label: ';

String multiSelectItemTemplate(
    int index, String option, bool selected, bool active) {
  final sb = StringBuffer();

  if (active) {
    sb.write('\x1b[7m');
  }

  sb.write(' ');

  if (selected) {
    sb.write('[X] $option');
  } else {
    sb.write('[ ] $option');
  }

  sb.write('\x1b[m');

  return sb.toString();
}

Future<List<String>> multiSelect(Tty tty, String name, List<String> options,
    {String question,
    Set<int> selected,
    MultiSelectPromptTemplate promptTemplate = multiSelectPromptTemplate,
    MultiSelectItemTemplate itemTemplate = multiSelectItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  final index = await multiSelectIndex(tty, name, options,
      question: question,
      selected: selected,
      promptTemplate: promptTemplate,
      itemTemplate: itemTemplate,
      success: success);
  return index.map((i) => options[i]).toList();
}

Future<Set<int>> multiSelectIndex(Tty tty, String name, List<String> options,
    {String question,
    Set<int> selected,
    int itemsPerPage = 5,
    MultiSelectPromptTemplate promptTemplate = multiSelectPromptTemplate,
    MultiSelectItemTemplate itemTemplate = multiSelectItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  if (selected != null) {
    selected = selected.toSet();
  } else {
    selected = {};
  }
  int active = 0;
  question ??= name;
  final pager = Pager(options, itemsPerPage: itemsPerPage);

  final mode = Mode(tty);
  mode.start();

  final buffer = TermBuffer(tty);

  final render = () async {
    final lines = <String>[];
    lines.add(
        promptTemplate(question, selected.map((i) => options[i]).toList()));
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
      content += itemTemplate(i, options[i], selected.contains(i), active == i);
      lines.add(content);
    }
    buffer.setContent(lines);
    await buffer.render();
  };

  await render();

  final completer = Completer();

  final sub = tty.runes.listen((List<int> data) async {
    bool shouldRender = true;
    final chars = tty.encoding.decode(data);
    if (chars.startsWith('\x1b[')) {
      final seq = chars.substring(2);
      if (seq == "A") {
        if (active > 0) {
          active--;
        } else {
          active = options.length - 1;
        }
        pager.moveToPageContainingIndex(active);
      } else if (seq == "B") {
        if (active < options.length - 1) {
          active++;
        } else {
          active = 0;
        }
        pager.moveToPageContainingIndex(active);
      } else if (seq == "5~") {
        if (pager.hasPreviousPage) {
          pager.goToPreviousPage();
          active = pager.lastIndexOfCurrentPage;
        } else {
          shouldRender = false;
          tty.ringBell();
        }
      } else if (seq == "6~") {
        if (pager.hasNextPage) {
          pager.goToNextPage();
          active = pager.startIndexOfCurrentPage;
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
    } else if (data.first == asciiSpace) {
      if (selected.contains(active)) {
        selected.remove(active);
      } else {
        selected.add(active);
      }
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
    // TODO multiSelect success template
    buffer.setContent(
        [success(name, selected.map((i) => options[i]).toString())]);
    await buffer.render();
  }

  mode.stop();

  return selected;
}
