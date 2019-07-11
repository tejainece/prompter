import 'package:prompter/io.dart';
import 'package:prompter/src/tty/tty.dart';

/// Reads multi-line text
Future<String> readMultiLineText(
  Tty tty, {
  String label = "",
  String default_ = "",
  Suggester suggester, // TODO
  LineTemplate<String> prompt = promptLineTemplate,
  // TODO line template
  SuccessTemplate<String> success = successTemplate,
}) async {
  // TODO
}
