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

Future<String> getString(Tty tty,
    {String label = "",
    String default_ = "",
    Validator<String> validator = noOpValidator,
    Suggester suggester,
    LineTemplate<String> prompt = promptLineTemplate,
    LineTemplate<String> main = mainLineTemplate,
    LineTemplate<String> postfix = noOpTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  return get(tty, StringStringer.instance,
      label: label,
      default_: default_,
      validator: validator,
      suggester: suggester,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success);
}
