import 'package:prompter/io.dart';

main(List<String> arguments) async {
  stdinBytes;

  await select('Color', ['Red', 'Blue', 'Green'], question: 'Choose a color');
}
