import 'package:prompter/src/validator.dart';

import 'package:prompter/prompter.dart';
import 'package:prompter/src/tty/tty.dart';

import 'get.dart';

class StringStringer implements Stringer<String> {
  const StringStringer();

  String from(String value) => value;

  String to(String value) => value;

  static const instance = StringStringer();
}

Future<String> readString(Tty tty,
    {String label = "",
    String default_ = "",
    Validator<String> validator = noOpValidator,
    Suggester suggester,
    LineTemplate<String> promptTemplate = promptTemplate,
    LineTemplate<String> contentTemplate = contentTemplate,
    LineTemplate<String> suffixTemplate = suffixTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  return read(tty, StringStringer.instance,
      label: label,
      default_: default_,
      validator: validator,
      suggester: suggester,
      promptTemplate: promptTemplate,
      contentTemplate: contentTemplate,
      suffixTemplate: suffixTemplate,
      success: success);
}
