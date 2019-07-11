import 'dart:convert';

import 'package:prompter/src/tty/tty.dart';

abstract class TextInput {
  String content;

  int get colNum;

  void moveToStartOfLine();

  void moveToEndOfLine();

  // TODO moveTo

  void moveForward();

  void moveBackward();

  void moveBackwardWord();

  void moveToEndWord();

  void moveForwardWord();

  void deleteToStartOfLine();

  void deleteToEndOfLine();

  void deleteLine();

  void deleteToStartOfWord();

  void deleteToEndOfWord();

  void writeChar(int char);

  void replaceChar(int char);

  void backspace();

  void del();

  bool get canMoveBackward;

  bool get canMoveForward;

  bool get canBackspace;

  bool get canDel;
}

class LineInput implements TextInput {
  var _content = <int>[];

  int _pos = 0;

  LineInput({String content = ""}) {
    this.content = content;
  }

  int get length => _content.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  int operator [](int index) {
    if (isEmpty) return null;
    if (index == length) return null;
    return _content[_pos];
  }

  int get currentChar => this[_pos];

  String get content => String.fromCharCodes(_content);

  set content(String value) {
    _content = value.runes.toList();
    moveToEndOfLine();
  }

  int get colNum => _pos;

  void moveToStartOfLine() {
    _pos = 0;
  }

  void moveToEndOfLine() {
    _pos = length;
  }

  void moveTo(int pos) {
    if (pos < 0 || pos > length) {
      throw RangeError.range(pos, 0, length, "pos");
    }

    _pos = pos;
  }

  void moveForward() {
    moveTo(_pos + 1);
  }

  void moveBackward() {
    moveTo(_pos - 1);
  }

  void moveBackwardWord() {
    if (_pos == 0) return;

    int p = _pos - 1;

    for (; p >= 0; p--) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    for (; p >= 0; p--) {
      if (!_isAlphaNumeric(_content[p])) break;
    }
    _pos = p + 1;
  }

  void moveToEndWord() {
    int p = _pos + 1;

    for (; p < length; p++) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    for (; p < length; p++) {
      if (!_isAlphaNumeric(_content[p])) break;
    }

    _pos = p - 1;
  }

  void moveForwardWord() {
    if (_pos == length) return;

    int p = _pos;

    if (_isAlphaNumeric(_content[p])) {
      for (; p < length; p++) {
        if (!_isAlphaNumeric(_content[p])) break;
      }
    }

    if (p == length) {
      _pos = p;
      return;
    }

    for (; p < length; p++) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    if (p == length) {
      _pos = p;
      return;
    }

    _pos = p;
  }

  void deleteToStartOfLine() {
    _content.removeRange(0, _pos);
    _pos = 0;
  }

  void deleteToEndOfLine() {
    _content.removeRange(_pos, length);
    _pos = length;
  }

  void deleteLine() {
    content = "";
  }

  void deleteToStartOfWord() {
    if (_pos == 0) return;

    int p = _pos - 1;

    for (; p >= 0; p--) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    for (; p >= 0; p--) {
      if (!_isAlphaNumeric(_content[p])) break;
    }

    _content.removeRange(p + 1, _pos);
    _pos = p + 1;
  }

  void deleteToEndOfWord() {
    if (_pos == length) return;

    int p = _pos;

    if (!_isAlphaNumeric(_content[p])) {
      for (; p < length; p++) {
        if (_isAlphaNumeric(_content[p])) break;
      }
    }

    for (; p < length; p++) {
      if (!_isAlphaNumeric(_content[p])) break;
    }

    _content.removeRange(_pos, p);
  }

  void writeChar(int char) {
    _content.insert(_pos, char);
    moveForward();
  }

  void writeChars(Iterable<int> chars) {
    _content.insertAll(_pos, chars);
    _pos += chars.length;
  }

  void replaceChar(int char) {
    if (length == 0 || _pos == length) {
      writeChar(char);
    } else {
      _content[_pos] = char;
      if (canMoveForward) moveForward();
    }
  }

  void backspace() {
    _content.removeAt(_pos - 1);
    moveBackward();
  }

  void del() {
    _content.removeAt(_pos);
  }

  bool get canMoveBackward => _pos > 0;

  bool get canMoveForward => _pos < length;

  bool get canBackspace => _pos > 0 && _content.isNotEmpty;

  bool get canDel => _pos < length;
}

class MultiLineInput implements TextInput {
  final _lines = <LineInput>[];

  int _curLineNum = 0;

  LineInput get _curLineInput => _lines[_curLineNum];

  MultiLineInput({String content = ''}) {
    this.content = content;
  }

  String get content => lines.join('\n');

  set content(String value) {
    _lines.clear();
    _lines.addAll(
        LineSplitter.split(value).map((l) => LineInput(content: l)).toList());
    if (_lines.isEmpty) _lines.add(LineInput());
    moveToEnd();
  }

  void moveToStart() {
    _curLineNum = 0;
    _curLineInput.moveToStartOfLine();
  }

  void moveToEnd() {
    _curLineNum = _lines.length - 1;
    _curLineInput.moveToEndOfLine();
  }

  int get colNum => _curLineInput.colNum;

  void moveToStartOfLine() => _curLineInput.moveToStartOfLine();

  void moveToEndOfLine() => _curLineInput.moveToEndOfLine();

  // TODO moveTo

  void moveForward() {
    if (_curLineInput.canMoveForward) {
      _curLineInput.moveForward();
    } else {
      _curLineNum++;
      _curLineInput.moveToStartOfLine();
    }
  }

  void moveBackward() {
    if (_curLineInput.canMoveBackward) {
      _curLineInput.moveBackward();
    } else {
      _curLineNum--;
      _curLineInput.moveToEndOfLine();
    }
  }

  void moveBackwardWord() {
    if (_curLineInput.canMoveBackward) {
      _curLineInput.moveBackwardWord();
    } else {
      _curLineNum--;
      _curLineInput.moveToEndOfLine();
      _curLineInput.moveBackwardWord();
    }
  }

  void moveToEndWord() {
    if (_curLineInput.canMoveForward) {
      _curLineInput.moveToEndWord();
    } else {
      _curLineNum++;
      _curLineInput.moveToStartOfLine();
      _curLineInput.moveToEndWord();
    }
  }

  void _moveForwardWordNextLine() {
    do {
      _curLineNum++;
      _curLineInput.moveToStartOfLine();
      if (_curLineInput.currentChar != null &&
          _isAlphaNumeric(_curLineInput.currentChar)) {
        break;
      }
      _curLineInput.moveForwardWord();
    } while (_curLineInput.colNum == _curLineInput.length && canMoveForward);
  }

  void moveForwardWord() {
    if (_curLineInput.canMoveForward) {
      _curLineInput.moveForwardWord();
      if (_curLineInput.colNum == _curLineInput.length && canMoveForward) {
        _moveForwardWordNextLine();
      }
    } else {
      _moveForwardWordNextLine();
    }
  }

  void deleteToStartOfLine() => _curLineInput.deleteToStartOfLine();

  void deleteToEndOfLine() => _curLineInput.deleteToEndOfLine();

  void deleteLine() => _curLineInput.deleteLine();

  void deleteToStartOfWord() => _curLineInput.deleteToStartOfWord();

  void deleteToEndOfWord() => _curLineInput.deleteToEndOfWord();

  void writeChar(int char) => _curLineInput.writeChar(char);

  void replaceChar(int char) => _curLineInput.replaceChar(char);

  void backspace() {
    if (_curLineInput.canBackspace) {
      _curLineInput.backspace();
    } else {
      final nextLine = _curLineInput.content;
      _lines.removeAt(_curLineNum);
      _curLineNum--;
      final pos = _curLineInput.colNum;
      _curLineInput.writeChars(nextLine.runes);
      _curLineInput.moveTo(pos);
    }
  }

  void del() {
    if (_curLineInput.canDel) {
      _curLineInput.del();
    } else {
      final nextLine = _lines.removeAt(_curLineNum + 1).content;
      final pos = _curLineInput.colNum;
      _curLineInput.writeChars(nextLine.runes);
      _curLineInput.moveTo(pos);
    }
  }

  bool get canMoveBackward {
    if (_curLineInput.canMoveBackward) return true;
    return _curLineNum != 0;
  }

  bool get canMoveForward {
    if (_curLineInput.canMoveForward) return true;
    return _curLineNum != _lines.length - 1;
  }

  bool get canBackspace {
    if (_curLineInput.canBackspace) return true;
    return _curLineNum != 0;
  }

  bool get canDel {
    if (_curLineInput.canDel) return true;
    return _curLineNum != _lines.length - 1;
  }

  void newLine() {
    final newLine = LineInput()
      ..writeChars(_curLineInput.content.runes.skip(_curLineInput.colNum));
    _curLineInput.deleteToEndOfLine();
    _lines.insert(_curLineNum + 1, newLine);
    _curLineNum++;
    _curLineInput.moveToStartOfLine();
  }

  List<String> get lines => _lines.map((l) => l.content).toList();

  int get lineNum => _curLineNum;
}

bool _isAlphaNumeric(int char) {
  if (char >= ascii0 && char <= ascii9) {
    return true;
  } else if (char >= asciia && char <= asciiz) {
    return true;
  } else if (char >= asciiA && char <= asciiZ) {
    return true;
  }

  return false;
}
