import 'package:prompter/src/tty/tty.dart';

class Mode {
  final Tty tty;

  bool _echoMode;

  bool _lineMode;

  Mode(this.tty);

  void start() {
    try {
      _echoMode = tty.echoMode;
      tty.echoMode = false;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off echoMode!");
    }
    try {
      _lineMode = tty.lineMode;
      tty.lineMode = false;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off lineMode!");
    }

    tty.hideCursor();
    // tty.disableWrap();
  }

  void stop() {
    tty.showCursor();
    // tty.enableWrap();

    try {
      tty.echoMode = _echoMode;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off echoMode!");
    }
    try {
      tty.lineMode = _lineMode;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off lineMode!");
    }
  }
}
