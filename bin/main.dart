import 'package:ansicolor/ansicolor.dart';
import 'package:prompter/io.dart';

class Person {
  String username;

  int age;

  double weight;

  Person({this.username, this.age, this.weight});

  @override
  String toString() {
    return {
      "username": username,
      "age": age,
      "weight": weight,
    }.toString();
  }
}

final greenPen = AnsiPen()..green();

final redPen = AnsiPen()..red();

final redBoldPen = AnsiPen()..red(bold: true);

String usernameValidator(String input) {
  if (input.contains(' ')) return 'Cannot contain spaces!';
  return null;
}

String prompt(String label, input, String error) {
  final sb = StringBuffer(' ');

  // Validity
  if (error != null) {
    sb.write(redPen('\u2717'));
  } else {
    sb.write(greenPen('\u2714'));
  }

  sb.write(' ');

  sb.write(label);

  sb.write(': ');

  return sb.toString();
}

String postfix(String label, input, String error) {
  final sb = StringBuffer();

  if (error != null) {
    sb.write(' ');
    sb.write(redBoldPen(error));
  }

  return sb.toString();
}

main(List<String> arguments) async {
  stdinBytes;

  final name = await readString(
      label: "\u{1F464} Username",
      default_: "Teja",
      promptTemplate: prompt,
      validator: usernameValidator,
      suffixTemplate: postfix,
      success: suffixTemplate);
  final age = await readInt(
    label: 'Age',
    promptTemplate: prompt,
    suffixTemplate: postfix,
  );
  final weight = await readDouble(
    label: 'Weight',
    promptTemplate: prompt,
    suffixTemplate: postfix,
  );

  final person = Person(username: name, age: age, weight: weight);

  print(person);
}
