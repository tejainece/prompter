import 'package:prompter/io.dart';

main(List<String> arguments) async {
  await select([
    'sdfgsdfg dfsgfdgdfgdfgdsfg df dfgdgdfg',
    'dfgdfgdfgdfg dfgdfsgdfsgdfgdg',
    'gdfgsdfgdsfgdsfgdsfgdfgdfg'
  ], name: "Random");
}
