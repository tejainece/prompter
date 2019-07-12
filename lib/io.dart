import 'package:meta/meta.dart';

import 'prompter.dart';
import 'prompter.dart' as prompter;
import 'src/tty/io.dart';

export 'prompter.dart';
export 'src/tty/io.dart';

final stdio = Stdio();

Future<String> readString(
        {String label = "",
        String default_ = "",
        Validator<String> validator = noOpValidator,
        Suggester suggester,
        LineTemplate<String> promptTemplate = promptTemplate,
        LineTemplate<String> contentTemplate = contentTemplate,
        LineTemplate<String> suffixTemplate = suffixTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.readString(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      suggester: suggester,
      promptTemplate: promptTemplate,
      contentTemplate: contentTemplate,
      suffixTemplate: suffixTemplate,
      success: success,
    );

Future<int> readInt(
        {String label = "",
        int default_,
        Validator<int> validator,
        LineTemplate<String> promptTemplate = promptTemplate,
        LineTemplate<String> contentTemplate = contentTemplate,
        LineTemplate<String> suffixTemplate = suffixTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.readInt(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      promptTemplate: promptTemplate,
      contentTemplate: contentTemplate,
      suffixTemplate: suffixTemplate,
      success: success,
    );

Future<double> readDouble(
        {String label = "",
        double default_,
        Validator<double> validator,
        LineTemplate<String> promptTemplate = promptTemplate,
        LineTemplate<String> contentTemplate = contentTemplate,
        LineTemplate<String> suffixTemplate = suffixTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.readDouble(
      stdio,
      label: label,
      default_: default_,
      validator: validator,
      promptTemplate: promptTemplate,
      contentTemplate: contentTemplate,
      suffixTemplate: suffixTemplate,
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

Future<String> readMultiLineText({
  String label = "",
  String default_ = "",
  Suggester suggester, // TODO
  PromptMultiLineTemplate promptTemplate = promptMultiLineTemplate,
  MultiLineLineTemplate linePrefixTemplate = multiLinePrefixTemplate,
  MultiLineLineTemplate lineTemplate = multiLineContentTemplate,
  SuccessTemplate<String> success = successTemplate,
}) =>
    prompter.readMultiLineText(stdio,
        label: label,
        default_: default_,
        suggester: suggester,
        promptTemplate: promptTemplate,
        linePrefixTemplate: linePrefixTemplate,
        lineTemplate: lineTemplate,
        success: success);
