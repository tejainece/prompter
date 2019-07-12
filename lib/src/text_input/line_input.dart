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

  void moveToEndOfWord();

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
      if (isAlphaNumeric(_content[p])) break;
    }

    for (; p >= 0; p--) {
      if (!isAlphaNumeric(_content[p])) break;
    }
    _pos = p + 1;
  }

  void moveToEndOfWord() {
    int p = _pos + 1;

    for (; p < length; p++) {
      if (isAlphaNumeric(_content[p])) break;
    }

    for (; p < length; p++) {
      if (!isAlphaNumeric(_content[p])) break;
    }

    if (p == length && !isAlphaNumeric(_content.last)) {
      _pos = length;
    } else {
      _pos = p - 1;
    }
  }

  void moveForwardWord() {
    if (_pos == length) return;

    int p = _pos;

    if (isAlphaNumeric(_content[p])) {
      for (; p < length; p++) {
        if (!isAlphaNumeric(_content[p])) break;
      }
    }

    if (p == length) {
      _pos = p;
      return;
    }

    for (; p < length; p++) {
      if (isAlphaNumeric(_content[p])) break;
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
      if (isAlphaNumeric(_content[p])) break;
    }

    for (; p >= 0; p--) {
      if (!isAlphaNumeric(_content[p])) break;
    }

    _content.removeRange(p + 1, _pos);
    _pos = p + 1;
  }

  void deleteToEndOfWord() {
    if (_pos == length) return;

    int p = _pos;

    if (!isAlphaNumeric(_content[p])) {
      for (; p < length; p++) {
        if (isAlphaNumeric(_content[p])) break;
      }
    }

    for (; p < length; p++) {
      if (!isAlphaNumeric(_content[p])) break;
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

bool isAlphaNumeric(int char) {
  if (char >= ascii0 && char <= ascii9) {
    return true;
  } else if (char >= asciia && char <= asciiz) {
    return true;
  } else if (char >= asciiA && char <= asciiZ) {
    return true;
  }

  return false;
}
