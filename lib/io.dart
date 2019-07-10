import 'package:meta/meta.dart';

import 'prompter.dart';
import 'prompter.dart' as prompter;
import 'src/tty/io.dart';

export 'prompter.dart';
export 'src/tty/io.dart';

final stdio = Stdio();

Future<String> getString(
        {String label = "",
        String default_ = "",
        Validator<String> validator = noOpValidator,
        Suggester suggester,
        LineTemplate<String> prompt = promptLineTemplate,
        LineTemplate<String> main = mainLineTemplate,
        LineTemplate<String> postfix = noOpTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.getString(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      suggester: suggester,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success,
    );

Future<int> getInt(
        {String label = "",
        int default_,
        Validator<int> validator,
        LineTemplate<String> prompt = promptLineTemplate,
        LineTemplate<String> main = mainLineTemplate,
        LineTemplate<String> postfix = noOpTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.getInt(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success,
    );

Future<double> getDouble(
        {String label = "",
        double default_,
        Validator<double> validator,
        LineTemplate<String> prompt = promptLineTemplate,
        LineTemplate<String> main = mainLineTemplate,
        LineTemplate<String> postfix = noOpTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.getDouble(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success,
    );

Future<String> select(List<String> options,
        {String question,
        @required String name,
        int selected = 0,
        SelectItemTemplate itemTemplate = defaultSelectItemTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.select(stdio, options,
        question: question,
        name: name,
        selected: selected,
        itemTemplate: itemTemplate,
        success: success);

// TODO selectIndex

Future<List<String>> multiSelect(List<String> options,
        {String question,
        @required String name,
        Set<int> selected,
        MultiSelectItemTemplate itemTemplate = defaultMultiSelectItemTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.multiSelect(stdio, options,
        question: question,
        name: name,
        selected: selected,
        itemTemplate: itemTemplate,
        success: success);

// TODO multiSelectIndex
