import 'dart:async';

class MapUpdateService {
  MapUpdateService._();

  static final MapUpdateService instance = MapUpdateService._();
  final StreamController<String> _updates =
      StreamController<String>.broadcast();

  Stream<String> get updates => _updates.stream;

  void notify(String reason) {
    _updates.add(reason);
  }
}
