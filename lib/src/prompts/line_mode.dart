import 'dart:io';

class Mode {
  bool _echoMode;

  bool _lineMode;

  Mode();

  void start() {
    try {
      _echoMode = stdin.echoMode;
      stdin.echoMode = false;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off echoMode!");
    }
    try {
      _lineMode = stdin.lineMode;
      stdin.lineMode = false;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off lineMode!");
    }

    stdout.write("\x1b[?25l");
  }

  void stop() {
    stdout.write("\x1b[?25h");

    try {
      stdin.echoMode = _echoMode;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off echoMode!");
    }
    try {
      stdin.lineMode = _lineMode;
    } catch (e) {
      throw UnsupportedError("Terminal does not support turning off lineMode!");
    }
  }
}
