import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show stdout, stdin;

import 'tty.dart';

class Stdio extends Tty {
  StreamSink<List<int>> get out => io.stdout;

  final Encoding encoding;

  Stdio({Encoding encoding}) : encoding = encoding ?? systemEncoding;

  bool get echoMode => io.stdin.echoMode;

  set echoMode(bool value) {
    io.stdin.echoMode = value;
  }

  bool get lineMode => io.stdin.lineMode;

  set lineMode(bool value) {
    io.stdin.lineMode = value;
  }

  Stream<List<int>> get bytes => stdinBytes;

  /*
  Future<Point<int>> get size => _getSize();

  Future<Point<int>> _getSize() async {
    ProcessResult lines = await Process.run("tput", ['lines']);
    ProcessResult cols = await Process.run("tput", ['cols']);
    if (lines.exitCode != 0 || cols.exitCode != 0) {
      throw Exception("Error executing tput");
    }
    return Point<int>(int.parse(cols.stdout), int.parse(lines.stdout));
  }
   */
}

Stream<List<int>> _stdin;

class TimedBytes {
  final DateTime time;

  final List<int> data;

  TimedBytes(this.time, this.data);
}

Stream<List<int>> get stdinBytes => _stdin ??= io.stdin.asBroadcastStream();
