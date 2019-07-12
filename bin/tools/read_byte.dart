import 'dart:io';

main() {
  stdin.echoMode = false;
  stdin.lineMode = false;
  while (true) {
    print(stdin.readByteSync());
  }
}
