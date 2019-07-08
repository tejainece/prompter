import 'package:prompter/src/validator.dart';

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

Future<int> getInt(
    {String label = "",
    int default_,
    Validator<int> validator,
    LineTemplate<String> prompt = promptLineTemplate,
    LineTemplate<String> main = mainLineTemplate,
    LineTemplate<String> postfix = noOpTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  if (validator == null) validator = intValidator();
  return get(IntStringer.instance,
      label: label,
      default_: default_,
      validator: validator,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success);
}
