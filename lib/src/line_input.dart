import 'package:prompter/src/tty/tty.dart';

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

class LineInput {
  var _content = <int>[];

  int _pos = 0;

  LineInput({String content = ""}) {
    this.content = content;
  }

  int get length => _content.length;

  String get content => String.fromCharCodes(_content);

  set content(String value) {
    _content = value.runes.toList();
    moveToEnd();
  }

  int get pos => _pos;

  void moveToStart() {
    _pos = 0;
  }

  void moveToEnd() {
    _pos = _content.length;
  }

  void moveTo(int pos) {
    if (pos < 0 || pos > _content.length) {
      throw RangeError.range(pos, 0, _content.length, "pos");
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

    for (; p < _content.length; p++) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    for (; p < _content.length; p++) {
      if (!_isAlphaNumeric(_content[p])) break;
    }

    _pos = p - 1;
  }

  void moveForwardWord() {
    if (_pos == _content.length) return;

    int p = _pos;

    if (_isAlphaNumeric(_content[p])) {
      for (; p < _content.length; p++) {
        if (!_isAlphaNumeric(_content[p])) break;
      }
    }

    if (p == _content.length) {
      _pos = p;
      return;
    }

    for (; p < _content.length; p++) {
      if (_isAlphaNumeric(_content[p])) break;
    }

    if (p == _content.length) {
      _pos = p;
      return;
    }

    _pos = p;
  }

  bool get canMoveBackward => _pos > 0;

  bool get canMoveForward => _pos < _content.length;

  void deleteToStart() {
    _content.removeRange(0, _pos);
    _pos = 0;
  }

  void deleteToEnd() {
    _content.removeRange(_pos, _content.length);
    _pos = _content.length;
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
    if(_pos == _content.length) return;

    int p = _pos;

    if(!_isAlphaNumeric(_content[p])) {
      for (; p < _content.length; p++) {
        if (_isAlphaNumeric(_content[p])) break;
      }
    }

    for (; p < _content.length; p++) {
      if (!_isAlphaNumeric(_content[p])) break;
    }

    _content.removeRange(_pos, p);
  }

  void writeChar(int char) {
    _content.insert(_pos, char);
    moveForward();
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

  bool get canBackspace => _pos > 0 && _content.isNotEmpty;

  bool get canDel => _pos < _content.length;
}
