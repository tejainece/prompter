import 'package:prompter/io.dart';

main(List<String> arguments) async {
  await multiSelect(['Red', 'Blue', 'Green'], name: "Color");
}
