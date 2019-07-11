import 'package:meta/meta.dart';
import 'dart:async';
import 'package:prompter/prompter.dart';
import 'package:prompter/src/tty/tty.dart';
import '../line_mode.dart';
import '../pager.dart';

typedef MultiSelectItemTemplate = String Function(
    int index, String option, bool selected, bool active);

String defaultMultiSelectItemTemplate(
    int index, String option, bool selected, bool active) {
  final sb = StringBuffer();

  if (active) {
    sb.write('>');
  } else {
    sb.write(' ');
  }

  sb.write(' ');

  if (selected) {
    // TODO
    sb.write('[X] $option');
  } else {
    sb.write('[ ] $option');
  }

  return sb.toString();
}

Future<List<String>> multiSelect(Tty tty, List<String> options,
    {String question,
    @required String name,
    Set<int> selected,
    MultiSelectItemTemplate itemTemplate = defaultMultiSelectItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  final index = await multiSelectIndex(tty, options,
      question: question,
      name: name,
      selected: selected,
      itemTemplate: itemTemplate,
      success: success);
  return index.map((i) => options[i]).toList();
}

Future<Set<int>> multiSelectIndex(Tty tty, List<String> options,
    {String question,
    @required String name,
    Set<int> selected,
    int itemsPerPage = 5,
    MultiSelectItemTemplate itemTemplate = defaultMultiSelectItemTemplate,
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
    lines.add(question); // TODO prompt template
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

  await buffer.init();

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
