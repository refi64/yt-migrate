extension MapWithIndex<T> on List<T> {
  Iterable<U> mapWithIndex<U>(U Function(int index, T value) func) =>
      Iterable<U>.generate(length, (index) => func(index, this[index]));
}

extension SortBy<T> on List<T> {
  void sortBy(dynamic Function(T item) key) =>
      sort((a, b) => key(a).compareTo(key(b)));
}

extension SortedBy<T> on Iterable<T> {
  List<T> sortedBy(dynamic Function(T item) key) =>
      List<T>.from(this)..sortBy(key);
}
