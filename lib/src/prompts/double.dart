import 'package:prompter/src/validator.dart';

import 'get.dart';

class DoubleStringer implements Stringer<double> {
  const DoubleStringer();

  String from(double value) => value.toString();

  double to(String value) => double.tryParse(value);

  static const instance = DoubleStringer();
}

Validator<double> doubleValidator({double min, double max}) {
  return (double input) {
    if (input == null) return 'Invalid number';
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

Future<double> getDouble(
    {String label = "",
    double default_,
    Validator<double> validator,
    LineTemplate<String> prompt = promptLineTemplate,
    LineTemplate<String> main = mainLineTemplate,
    LineTemplate<String> postfix = noOpTemplate,
    SuccessTemplate<String> success = successTemplate}) async {
  if (validator == null) validator = doubleValidator();
  return get(DoubleStringer.instance,
      label: label,
      default_: default_,
      validator: validator,
      prompt: prompt,
      main: main,
      postfix: postfix,
      success: success);
}
