import 'package:prompter/src/validator.dart';
import 'package:prompter/src/tty/tty.dart';

import 'get.dart';

class IntStringer implements Stringer<int> {
  const IntStringer();

  String from(int value) => value.toString();

  int to(String value) => int.tryParse(value);

  static const instance = IntStringer();
}

Validator<int> intValidator({int min, int max}) {
  return (int input) {
    if (input == null) return 'Invalid integer';
    if (min != null) {
      if (input < min) {
        return 'Should be less than $min';
      }
    }
    if (max != null) {
      if (input > max) {
        return 'Should be greater than $max';
      }
    }
  };
}

Future<int> readInt(Tty tty,
    {String label = "",
    int default_,
    Validator<int> validator,
    LineTemplate<String> promptTemplate = promptTemplate,
    LineTemplate<String> contentTemplate = contentTemplate,
    LineTemplate<String> suffixTemplate = suffixTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  if (validator == null) validator = intValidator();
  return read(tty, IntStringer.instance,
      label: label,
      default_: default_,
      validator: validator,
      promptTemplate: promptTemplate,
      contentTemplate: contentTemplate,
      suffixTemplate: suffixTemplate,
      success: success);
}
