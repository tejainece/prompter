class Pager<T> {
  final List<T> items;

  final int itemsPerPage;

  int _curPage = 0;

  int get numPages => (items.length / itemsPerPage).ceil();

  Pager(List<T> items, {this.itemsPerPage = 5}) : items = items.toList();

  bool get hasNextPage => !isInLastPage;

  bool get hasPreviousPage => _curPage > 0;

  bool get isInLastPage => _curPage == numPages - 1;

  void goToNextPage() {
    if (isInLastPage) throw Exception("At last page");
    _curPage++;
  }

  void goToPreviousPage() {
    if (!hasPreviousPage) throw Exception("At first page");
    _curPage--;
  }

  void moveToPageContainingIndex(int index) {
    final newCurPage = index ~/ itemsPerPage;
    // TODO range check
    _curPage = newCurPage;
  }

  int get startIndexOfCurrentPage => _curPage * itemsPerPage;

  int get lastIndexOfCurrentPage {
    if (isInLastPage) return items.length - 1;
    return startIndexOfCurrentPage + itemsPerPage - 1;
  }

  List<T> get currentPageItems {
    return items.sublist(startIndexOfCurrentPage, lastIndexOfCurrentPage + 1);
  }

  bool get needsPaging => items.length > itemsPerPage;
}
