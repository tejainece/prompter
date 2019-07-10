class LineInput {
  var _content = <int>[];

  int _pos = 0;

  LineInput({String content = ""}) {
    _content = content.codeUnits.toList();
    _pos = _content.length;
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
