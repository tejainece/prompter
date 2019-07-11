import 'package:prompter/io.dart';

main(List<String> arguments) async {
  stdinBytes;

  await select(
      List<String>.generate(26, (i) => String.fromCharCode(i + 65)),
      name: "Alphabet");
}
