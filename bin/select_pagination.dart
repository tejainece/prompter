import 'package:prompter/prompter.dart';

main(List<String> arguments) async {
  final color = await select(
      List<String>.generate(26, (i) => String.fromCharCode(i + 65)),
      name: "Alphabet");
}
