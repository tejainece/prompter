import 'package:prompter/io.dart';

main(List<String> arguments) async {
  stdinBytes;

  await multiSelect(['Red', 'Blue', 'Green'], name: "Color");
}
