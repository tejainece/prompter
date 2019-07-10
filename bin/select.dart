import 'package:prompter/io.dart';

main(List<String> arguments) async {
  await select(['Red', 'Blue', 'Green'], name: "Color");
}
