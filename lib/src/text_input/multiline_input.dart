import 'dart:convert';

import 'line_input.dart';

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

  void _moveBackwardWordNextLine() {
    do {
      _curLineNum--;
      _curLineInput.moveToEndOfLine();
      _curLineInput.moveBackwardWord();

      if (_curLineInput.currentChar != null &&
          isAlphaNumeric(_curLineInput.currentChar)) {
        break;
      }
    } while (canMoveBackward);
  }

  void moveBackwardWord() {
    if (_curLineInput.canMoveBackward) {
      _curLineInput.moveBackwardWord();
      if (!isAlphaNumeric(_curLineInput.currentChar) && canMoveBackward) {
        _moveBackwardWordNextLine();
      }
    } else {
      _moveBackwardWordNextLine();
    }
  }

  void _moveEndOfWordNextLine() {
    do {
      _curLineNum++;
      _curLineInput.moveToStartOfLine();
      _curLineInput.moveToEndOfWord();
      if (_curLineInput.currentChar != null &&
          isAlphaNumeric(_curLineInput.currentChar)) {
        break;
      }
    } while (_curLineInput.colNum == _curLineInput.length && canMoveForward);
  }

  void moveToEndOfWord() {
    if (_curLineInput.canMoveForward) {
      if(_curLineInput.colNum < _curLineInput.length - 1) {
        _curLineInput.moveToEndOfWord();
        if (_curLineInput.colNum == _curLineInput.length && canMoveForward) {
          _moveEndOfWordNextLine();
        }
      } else {
        if(canMoveDown) {
          _moveEndOfWordNextLine();
        }
      }
    } else {
      _moveEndOfWordNextLine();
    }
  }

  void _moveForwardWordNextLine() {
    do {
      _curLineNum++;
      _curLineInput.moveToStartOfLine();
      if (_curLineInput.currentChar != null &&
          isAlphaNumeric(_curLineInput.currentChar)) {
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

  bool get canMoveUp => _curLineNum != 0;

  bool get canMoveDown => _curLineNum < _lines.length - 1;

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

  void moveUp({int pos}) {
    pos ??= _curLineInput.colNum;
    _curLineNum--;
    if (pos <= _curLineInput.length) {
      _curLineInput.moveTo(pos);
    } else {
      _curLineInput.moveToEndOfLine();
    }
  }

  void moveDown({int pos}) {
    pos ??= _curLineInput.colNum;
    _curLineNum++;
    if (pos <= _curLineInput.length) {
      _curLineInput.moveTo(pos);
    } else {
      _curLineInput.moveToEndOfLine();
    }
  }
}
