import 'package:prompter/prompter.dart';

main(List<String> arguments) async {
  await select(['Red', 'Blue', 'Green'], name: "Color");
}
