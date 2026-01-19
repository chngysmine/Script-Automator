/// Registry to manage Dart objects (Host Objects) that are exposed to JavaScript.
///
/// This registry allows mapping a unique ID (integer) to a Dart object instance.
/// It is used when passing objects from Dart to JS (as an ID) and retrieving them
/// when JS calls methods on the object (via the ID).
class HostObjectRegistry {
  static final HostObjectRegistry _instance = HostObjectRegistry._internal();
  final Map<int, Object> _registry = {};
  int _nextId = 1;

  factory HostObjectRegistry() {
    return _instance;
  }

  HostObjectRegistry._internal();

  /// Registers an object and returns its unique ID.
  int register(Object object) {
    final id = _nextId++;
    _registry[id] = object;
    return id;
  }

  /// Retrieves an object by its ID.
  Object? get(int id) {
    return _registry[id];
  }

  /// Removes an object from the registry.
  void unregister(int id) {
    _registry.remove(id);
  }

  /// Clears all registered objects.
  void clear() {
    _registry.clear();
    _nextId = 1;
  }
}
