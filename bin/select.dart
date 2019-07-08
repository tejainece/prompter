import 'package:prompter/prompter.dart';

main(List<String> arguments) async {
  final color = await select(['Red', 'Blue', 'Green'], name: "Color");
}
