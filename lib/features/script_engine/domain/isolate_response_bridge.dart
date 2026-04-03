import 'dart:async';

/// Manages synchronous-style communication between the JS Isolate and Main Isolate.
/// Allows the Isolate to "wait" for a response from the Main Isolate.
class IsolateResponseBridge {
  static final IsolateResponseBridge _instance = IsolateResponseBridge._internal();
  factory IsolateResponseBridge() => _instance;
  IsolateResponseBridge._internal();

  final Map<int, Completer<dynamic>> _pendingRequests = {};
  int _nextRequestId = 1;

  /// Registers a new request and returns the [requestId] and a [Completer]
  /// to wait for the response.
  (int, Completer<dynamic>) createRequest() {
    final requestId = _nextRequestId++;
    final completer = Completer<dynamic>();
    _pendingRequests[requestId] = completer;
    return (requestId, completer);
  }

  /// Completes a pending request with the given [response].
  /// This should be called when the Main Isolate sends back the result.
  void completeRequest(int requestId, dynamic response) {
    final completer = _pendingRequests.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  /// Cancels a pending request with an error.
  void completeWithError(int requestId, Object error) {
    final completer = _pendingRequests.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  /// Clears all pending requests, useful during engine reload/crash.
  void clear() {
    for (var completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError("Response bridge cleared"));
      }
    }
    _pendingRequests.clear();
  }
}
