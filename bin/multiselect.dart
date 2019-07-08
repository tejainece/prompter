import 'package:prompter/prompter.dart';

main(List<String> arguments) async {
  await multiSelect(['Red', 'Blue', 'Green'], name: "Color");
}
