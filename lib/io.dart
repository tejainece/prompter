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

Future<String> select(String name, List<String> options,
        {String question,
        int selected = 0,
        SelectPromptTemplate promptTemplate = prompter.selectPromptTemplate,
        SelectItemTemplate itemTemplate = selectItemTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.select(stdio, name, options,
        question: question,
        selected: selected,
        promptTemplate: promptTemplate,
        itemTemplate: itemTemplate,
        success: success);

// TODO selectIndex

Future<List<String>> multiSelect(String name, List<String> options,
        {String question,
        Set<int> selected,
        MultiSelectPromptTemplate promptTemplate = multiSelectPromptTemplate,
        MultiSelectItemTemplate itemTemplate = multiSelectItemTemplate,
        SuccessTemplate<String> success = successTemplate}) =>
    prompter.multiSelect(stdio, name, options,
        question: question,
        selected: selected,
        promptTemplate: promptTemplate,
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
