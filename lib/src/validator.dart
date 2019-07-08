class Suggestion {
  final String title;

  final String annotation;

  Suggestion(this.title, this.annotation);
}

typedef Suggester = List<Suggestion> Function(String input, int cursorPos);

typedef Validator<T> = String Function(T input);

String noOpValidator(_) => null;

typedef LineTemplate<T> = String Function(String label, T input, String error);

String promptLineTemplate(String label, _1, _2) => '$label: ';

String mainLineTemplate<T>(_, input, _2) => '$input';

String noOpTemplate(_, _1, [_2]) => '';

typedef SuccessTemplate<T> = String Function(String label, T input);

String successTemplate(String label, input) => "$label: $input\r\n";
