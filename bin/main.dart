import 'package:ansicolor/ansicolor.dart';
import 'package:prompter/prompter.dart';

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
  final name = await getString(
      label: "Username",
      default_: "Teja",
      prompt: prompt,
      validator: usernameValidator,
      postfix: postfix,
      success: noOpTemplate);
  final age = await getInt(
    label: 'Age',
    prompt: prompt,
    postfix: postfix,
  );
  final weight = await getDouble(
    label: 'Weight',
    prompt: prompt,
    postfix: postfix,
  );

  final person = Person(username: name, age: age, weight: weight);

  print(person);
}
