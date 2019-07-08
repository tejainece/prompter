import 'dart:io';
import 'package:meta/meta.dart';
import 'dart:async';
import 'package:prompter/prompter.dart';
import '../line_mode.dart';

typedef SelectOneItemTemplate = String Function(
    int index, String option, bool selected);

String defaultSelectOneItemTemplate(int index, String option, bool selected) {
  if (selected) {
    return '> $option';
    // TODO
  } else {
    return '  $option';
  }
}

class Pager<T> {
  final List<T> items;

  final int itemsPerPage;

  int _curPage = 0;

  int get numPages => (items.length / itemsPerPage).ceil();

  Pager(List<T> items, {this.itemsPerPage = 5}) : items = items.toList();

  bool get hasNextPage => !isInLastPage;

  bool get hasPreviousPage => _curPage > 0;

  bool get isInLastPage => _curPage == numPages - 1;

  void goToNextPage() {
    if (isInLastPage) throw Exception("At last page");
    _curPage++;
  }

  void goToPreviousPage() {
    if (!hasPreviousPage) throw Exception("At first page");
    _curPage--;
  }

  void moveToPageContainingIndex(int index) {
    final newCurPage = index ~/ itemsPerPage;
    // TODO range check
    _curPage = newCurPage;
  }

  int get startIndexOfCurrentPage => _curPage * itemsPerPage;

  int get lastIndexOfCurrentPage {
    if (isInLastPage) return items.length - 1;
    return startIndexOfCurrentPage + itemsPerPage - 1;
  }

  List<T> get currentPageItems {
    return items.sublist(startIndexOfCurrentPage, lastIndexOfCurrentPage + 1);
  }

  bool get needsPaging => items.length > itemsPerPage;
}

Future<String> select(List<String> options,
    {String question,
    @required String name,
    int selected = 0,
    SelectOneItemTemplate itemTemplate = defaultSelectOneItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  final index = await selectIndex(options,
      question: question,
      name: name,
      selected: selected,
      itemTemplate: itemTemplate,
      success: success);
  return options[index];
}

Future<int> selectIndex(List<String> options,
    {String question,
    @required String name,
    int selected = 0,
    int itemsPerPage = 5,
    SelectOneItemTemplate itemTemplate = defaultSelectOneItemTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  question ??= name;
  final pager = Pager(options, itemsPerPage: itemsPerPage);

  final mode = Mode();
  mode.start();

  final buffer = TermBuffer();

  final render = () {
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
      content += itemTemplate(i, options[i], selected == i);
      lines.add(content);
    }
    buffer.setContent(lines);
  };

  await buffer.start();

  render();

  final completer = Completer();

  final sub = listen((List<int> data) {
    bool shouldRender = true;
    final chars = systemEncoding.decode(data);
    if (data.first == asciiEscape) {
      if (chars == "\x1b[A") {
        if (selected > 0) {
          selected--;
        } else {
          selected = options.length - 1;
        }
        pager.moveToPageContainingIndex(selected);
      } else if (chars == "\x1b[B") {
        if (selected < options.length - 1) {
          selected++;
        } else {
          selected = 0;
        }
        pager.moveToPageContainingIndex(selected);
      } else if (chars == "\x1b[5~") {
        if (pager.hasPreviousPage) {
          pager.goToPreviousPage();
          selected = pager.lastIndexOfCurrentPage;
        } else {
          shouldRender = false;
          stdout.write("\x07");
        }
      } else if (chars == "\x1b[6~") {
        if (pager.hasNextPage) {
          pager.goToNextPage();
          selected = pager.startIndexOfCurrentPage;
        } else {
          shouldRender = false;
          stdout.write("\x07");
        }
      } else {
        // stdout.write(data);
      }
    } else if (data.first == 10) {
      completer.complete();
      return;
    } else {
      // stdout.write(data);
    }
    if (shouldRender) render();
  });

  await completer.future;
  await sub.cancel();

  buffer.stop();

  {
    buffer.setContent([success(name, options[selected])]);
    buffer.render();
  }

  mode.stop();

  return selected;
}
