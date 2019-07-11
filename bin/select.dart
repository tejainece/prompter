import 'package:prompter/io.dart';

main(List<String> arguments) async {
  stdinBytes;

  await select(['Red', 'Blue', 'Green'], name: "Color");
}
