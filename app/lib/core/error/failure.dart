/// A recoverable error crossing a layer boundary (data -> domain -> UI).
class Failure implements Exception {
  const Failure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'Failure: $message${cause == null ? '' : ' ($cause)'}';
}
