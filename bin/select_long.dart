import 'package:prompter/io.dart';

main(List<String> arguments) async {
  stdinBytes;

  await select("Random string", [
    'sdfgsdfg dfsgfdgdfgdfgdsfg df dfgdgdfg',
    'dfgdfgdfgdfg dfgdfsgdfsgdfgdg',
    'gdfgsdfgdsfgdsfgdsfgdfgdfg'
  ]);
}
