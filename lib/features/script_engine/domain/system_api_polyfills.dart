/// Polyfill bundle injects namespace objects into the JS environment before script execution.
/// Works around the limitation of QuickJS/JSC FFI single string argument callbacks.
class SystemAPIPolyfills {
  /// Polyfill for console.log, console.error, console.warn.
  /// Formats arguments into a single string pipe separated with the log level
  /// and calls the native __native_console function.
  static const String consolePolyfill = '''
    var console = {
      // Helper to serialize arguments properly
      _serializeArgs: function(args) {
        var str = "";
        for (var i = 0; i < args.length; i++) {
          var param = args[i];
          if (param === null) str += "null";
          else if (param === void 0) str += "undefined";
          else if (typeof param === "object") {
            try {
              str += JSON.stringify(param);
            } catch (e) {
              str += "[Object]";
            }
          } else {
            str += param.toString();
          }
          if (i < args.length - 1) str += " ";
        }
        return str;
      },
      log: function() { __native_console('log|' + this._serializeArgs(arguments)); },
      error: function() { __native_console('error|' + this._serializeArgs(arguments)); },
      warn: function() { __native_console('warn|' + this._serializeArgs(arguments)); },
      info: function() { __native_console('info|' + this._serializeArgs(arguments)); },
      debug: function() { __native_console('debug|' + this._serializeArgs(arguments)); }
    };
  ''';

  /// Polyfill for fetch() - executed asynchronously using Promises.
  /// Works around Dart Isolate synchronous blocking limitations.
  static const String fetchPolyfill = '''
    // Global registry for pending native async tasks
    var __pendingTasks = {};
    var __nextTaskId = 1;

    // Called by Dart when an async response arrives
    function __resolve_async_task(reqId, responseJsonString) {
      if (__pendingTasks[reqId]) {
         var response = JSON.parse(responseJsonString);
         if (response.error) {
           __pendingTasks[reqId].reject(new Error(response.error));
         } else {
           __pendingTasks[reqId].resolve(response);
         }
         delete __pendingTasks[reqId];
      }
    }

    // Polyfill standard fetch API returning a Promise
    var fetch = function(url, options) {
      return new Promise(function(resolve, reject) {
        options = options || {};
        var reqId = __nextTaskId++;
        
        // Wrap the standard resolve/reject to format the response object
        __pendingTasks[reqId] = { 
            resolve: function(res) {
                var responseObject = {
                    ok: res.status >= 200 && res.status < 300,
                    status: res.status,
                    headers: res.headers || {},
                    body: res.body, // original string
                    text: function() { return Promise.resolve(res.body); },
                    json: function() { 
                      try { return Promise.resolve(JSON.parse(res.body)); } 
                      catch(e) { return Promise.reject(e); } 
                    }
                };
                resolve(responseObject);
            }, 
            reject: reject 
        };
        
        var request = {
          __reqId: reqId,
          url: url,
          method: options.method || 'GET',
          headers: options.headers || {},
          body: options.body || null
        };
        
        __native_fetch_start(JSON.stringify(request));
      });
    };
  ''';

  /// Polyfill for Device querying (Synchronous capability via simple bridge if needed, or async)
  /// For simplicity, Device info is fetched asynchronously since isolate communication takes a tick.
  static const String devicePolyfill = '''
    var Device = {
      _request: function(property) {
        return new Promise(function(resolve, reject) {
          var reqId = __nextTaskId++;
          __pendingTasks[reqId] = { resolve: resolve, reject: reject };
          __native_device_info_start(JSON.stringify({ __reqId: reqId, property: property }));
        });
      },
      osVersion: function() { return this._request('osVersion').then(function(r) { return r.value; }); },
      model: function() { return this._request('model').then(function(r) { return r.value; }); },
      locale: function() { return this._request('locale').then(function(r) { return r.value; }); },
      systemName: function() { return this._request('os').then(function(r) { return r.value; }); }
    };
  ''';

  /// Polyfill for Keychain (Secure Storage) - Asynchronous
  static const String keychainPolyfill = '''
    var Keychain = {
      _request: function(action, key, value) {
        return new Promise(function(resolve, reject) {
          var reqId = __nextTaskId++;
          __pendingTasks[reqId] = { resolve: resolve, reject: reject };
          __native_keychain_start(JSON.stringify({ 
              __reqId: reqId, 
              action: action, 
              key: key, 
              value: value 
          }));
        });
      },
      set: function(key, value) { return this._request('set', key, value).then(function() { return true; }); },
      get: function(key) { return this._request('get', key).then(function(res) { return res.value; }); },
      remove: function(key) { return this._request('delete', key).then(function() { return true; }); }
    };
  ''';

  /// Polyfill for Notification (Local Notifications) - Asynchronous
  static const String notificationPolyfill = '''
    var Notification = {
      schedule: function(options) {
        return new Promise(function(resolve, reject) {
          options = options || {};
          var reqId = __nextTaskId++;
          __pendingTasks[reqId] = { resolve: resolve, reject: reject };
          __native_notification_start(JSON.stringify({ 
              __reqId: reqId, 
              title: options.title || '', 
              body: options.body || '',
              id: options.id || null
          }));
        });
      }
    };
  ''';

  /// Polyfill for Widget Family handling
  static const String widgetPolyfill = '''
    var __widgetState = {};
    var Widget = {
      _family: 'medium',
      _actionHandlers: {},
      setFamily: function(family) {
        this._family = family;
      },
      getFamily: function() {
        return this._family;
      },
      presentSize: function() {
        return (typeof __widget_present_size !== 'undefined') ? __widget_present_size : 'medium';
      },
      onAction: function(actionId, callback) {
        this._actionHandlers[actionId] = callback;
      },
      getState: function(key, defaultVal) {
        return Object.prototype.hasOwnProperty.call(__widgetState, key) ? __widgetState[key] : defaultVal;
      },
      setState: function(key, val) {
        __widgetState[key] = val;
        return val;
      }
    };
  ''';

  /// Polyfill to make Promise resolving work smoothly in headless engines
  /// If the engine doesn't flush promises automatically, this helps tick the microtask queue.

  /// Returns all polyfills concatenated, ready for injection.
  static String get allPolyfills => [
        consolePolyfill,
        fetchPolyfill,
        devicePolyfill,
        keychainPolyfill,
        notificationPolyfill,
        widgetPolyfill,
      ].join('\n');
}
