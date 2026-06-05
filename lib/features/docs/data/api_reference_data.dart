class ApiEntry {
  final String name;
  final String category;
  final String signature;
  final String description;
  final String example;
  final String? returnType;
  final List<ApiParam>? params;

  const ApiEntry({
    required this.name,
    required this.category,
    required this.signature,
    required this.description,
    required this.example,
    this.returnType,
    this.params,
  });
}

class ApiParam {
  final String name;
  final String type;
  final String description;
  final bool required;

  const ApiParam({
    required this.name,
    required this.type,
    required this.description,
    required this.required,
  });
}

final List<ApiEntry> apiReference = [
  ApiEntry(
    name: 'console.log',
    category: 'Console',
    signature: 'console.log(...args)',
    description: 'Writes an informational message to the debug console.',
    returnType: 'void',
    params: [
      ApiParam(name: 'args', type: 'any[]', description: 'Values to print.', required: true),
    ],
    example: '''console.log('Widget loaded:', Widget.getFamily());''',
  ),
  ApiEntry(
    name: 'console.error',
    category: 'Console',
    signature: 'console.error(...args)',
    description: 'Writes an error message to the debug console.',
    returnType: 'void',
    params: [
      ApiParam(name: 'args', type: 'any[]', description: 'Values to print.', required: true),
    ],
    example: '''try {
  throw new Error('Boom');
} catch (e) {
  console.error('Failed to render:', e);
}''',
  ),
  ApiEntry(
    name: 'console.warn',
    category: 'Console',
    signature: 'console.warn(...args)',
    description: 'Writes a warning message to the debug console.',
    returnType: 'void',
    params: [
      ApiParam(name: 'args', type: 'any[]', description: 'Values to print.', required: true),
    ],
    example: '''console.warn('Using fallback data because the network is unavailable.');''',
  ),
  ApiEntry(
    name: 'console.info',
    category: 'Console',
    signature: 'console.info(...args)',
    description: 'Writes an informational message to the debug console.',
    returnType: 'void',
    params: [
      ApiParam(name: 'args', type: 'any[]', description: 'Values to print.', required: true),
    ],
    example: '''console.info('Refreshing widget state...');''',
  ),
  ApiEntry(
    name: 'console.debug',
    category: 'Console',
    signature: 'console.debug(...args)',
    description: 'Writes a debug message to the debug console.',
    returnType: 'void',
    params: [
      ApiParam(name: 'args', type: 'any[]', description: 'Values to print.', required: true),
    ],
    example: '''console.debug({ step: 'parse', ok: true });''',
  ),
  ApiEntry(
    name: 'fetch',
    category: 'Network',
    signature: 'fetch(url, options)',
    description: 'Performs an HTTP request and returns a Promise that resolves to a Response-like object with text() and json() helpers.',
    returnType: 'Promise<ResponseLike>',
    params: [
      ApiParam(name: 'url', type: 'string', description: 'Request URL.', required: true),
      ApiParam(name: 'options', type: 'object', description: 'Method, headers, and body.', required: false),
    ],
    example: '''const response = await fetch('https://api.example.com/profile', {
  method: 'GET',
  headers: { 'Accept': 'application/json' }
});

if (!response.ok) {
  throw new Error('Request failed');
}

const data = await response.json();
console.log(data.name);''',
  ),
  ApiEntry(
    name: 'Device.osVersion',
    category: 'Device',
    signature: 'Device.osVersion()',
    description: 'Returns the operating system version of the current device.',
    returnType: 'Promise<string>',
    params: [],
    example: '''const osVersion = await Device.osVersion();
console.log(osVersion);''',
  ),
  ApiEntry(
    name: 'Device.model',
    category: 'Device',
    signature: 'Device.model()',
    description: 'Returns a friendly model name for the current device.',
    returnType: 'Promise<string>',
    params: [],
    example: '''const model = await Device.model();
console.log(model);''',
  ),
  ApiEntry(
    name: 'Device.locale',
    category: 'Device',
    signature: 'Device.locale()',
    description: 'Returns the current locale string.',
    returnType: 'Promise<string>',
    params: const [],
    example: '''const locale = await Device.locale();
console.log(locale);''',
  ),
  ApiEntry(
    name: 'Device.systemName',
    category: 'Device',
    signature: 'Device.systemName()',
    description: 'Returns the platform name such as ios, android, or web.',
    returnType: 'Promise<string>',
    params: const [],
    example: '''const systemName = await Device.systemName();
console.log(systemName);''',
  ),
  ApiEntry(
    name: 'Keychain.set',
    category: 'Storage',
    signature: 'Keychain.set(key, value)',
    description: 'Stores a string value securely in device keychain or secure storage.',
    returnType: 'Promise<boolean>',
    params: [
      ApiParam(name: 'key', type: 'string', description: 'Storage key.', required: true),
      ApiParam(name: 'value', type: 'string', description: 'Value to store.', required: true),
    ],
    example: '''await Keychain.set('theme', 'dark');''',
  ),
  ApiEntry(
    name: 'Keychain.get',
    category: 'Storage',
    signature: 'Keychain.get(key)',
    description: 'Reads a secure value from keychain or secure storage.',
    returnType: 'Promise<string?>',
    params: [
      ApiParam(name: 'key', type: 'string', description: 'Storage key.', required: true),
    ],
    example: '''const theme = await Keychain.get('theme') || 'light';
console.log(theme);''',
  ),
  ApiEntry(
    name: 'Keychain.remove',
    category: 'Storage',
    signature: 'Keychain.remove(key)',
    description: 'Deletes a secure value from keychain or secure storage.',
    returnType: 'Promise<boolean>',
    params: [
      ApiParam(name: 'key', type: 'string', description: 'Storage key.', required: true),
    ],
    example: '''await Keychain.remove('theme');''',
  ),
  ApiEntry(
    name: 'Notification.schedule',
    category: 'Notification',
    signature: 'Notification.schedule({ title, body, id })',
    description: 'Schedules a local notification on the device.',
    returnType: 'Promise<void>',
    params: [
      ApiParam(name: 'title', type: 'string', description: 'Notification title.', required: true),
      ApiParam(name: 'body', type: 'string', description: 'Notification body.', required: false),
      ApiParam(name: 'id', type: 'number', description: 'Optional notification identifier.', required: false),
    ],
    example: '''await Notification.schedule({
  title: 'Widget Updated',
  body: 'Your script finished rendering.',
  id: 42,
});''',
  ),
  ApiEntry(
    name: 'Widget.setFamily',
    category: 'Widget',
    signature: 'Widget.setFamily(family)',
    description: 'Sets the current widget family for responsive rendering.',
    returnType: 'void',
    params: [
      ApiParam(name: 'family', type: 'string', description: 'Widget family such as small, medium, or large.', required: true),
    ],
    example: '''Widget.setFamily('medium');''',
  ),
  ApiEntry(
    name: 'Widget.getFamily',
    category: 'Widget',
    signature: 'Widget.getFamily()',
    description: 'Returns the current widget family.',
    returnType: 'string',
    params: const [],
    example: '''const family = Widget.getFamily();
console.log(family);''',
  ),
  ApiEntry(
    name: 'Widget.presentSize',
    category: 'Widget',
    signature: 'Widget.presentSize()',
    description: 'Returns the present widget size hint used by the runtime.',
    returnType: 'string',
    params: const [],
    example: '''const size = Widget.presentSize();
console.log(size);''',
  ),
  ApiEntry(
    name: 'Widget.onAction',
    category: 'Widget',
    signature: 'Widget.onAction(actionId, callback)',
    description: 'Registers a callback that runs when a native widget button is tapped.',
    returnType: 'void',
    params: [
      ApiParam(name: 'actionId', type: 'string', description: 'Button action identifier.', required: true),
      ApiParam(name: 'callback', type: 'function', description: 'Callback to execute on tap.', required: true),
    ],
    example: '''Widget.onAction('refresh', async function() {
  const profile = await fetch('https://api.example.com/me').then(r => r.json());
  Widget.setState('name', profile.name);
  renderWidget(JSON.stringify(buildWidget(profile)));
});''',
  ),
  ApiEntry(
    name: 'Widget.getState',
    category: 'Widget',
    signature: 'Widget.getState(key, defaultVal)',
    description: 'Reads a widget-scoped state value from the in-memory state store.',
    returnType: 'any',
    params: [
      ApiParam(name: 'key', type: 'string', description: 'State key.', required: true),
      ApiParam(name: 'defaultVal', type: 'any', description: 'Fallback value when key is missing.', required: false),
    ],
    example: '''const count = Widget.getState('count', 0);''',
  ),
  ApiEntry(
    name: 'Widget.setState',
    category: 'Widget',
    signature: 'Widget.setState(key, val)',
    description: 'Stores a widget-scoped state value in memory.',
    returnType: 'any',
    params: [
      ApiParam(name: 'key', type: 'string', description: 'State key.', required: true),
      ApiParam(name: 'val', type: 'any', description: 'Value to store.', required: true),
    ],
    example: '''const next = (Widget.getState('count', 0) || 0) + 1;
Widget.setState('count', next);''',
  ),
  ApiEntry(
    name: 'renderWidget',
    category: 'Rendering',
    signature: 'renderWidget(jsonString)',
    description: 'Renders a SASUP widget tree using the native widget renderers.',
    returnType: 'string',
    params: [
      ApiParam(name: 'jsonString', type: 'string', description: 'Serialized SASUP JSON tree.', required: true),
    ],
    example: '''const widget = {
  type: 'container',
  modifiers: { background: '#111827', cornerRadius: 24, padding: { all: 16 } },
  children: [
    { type: 'text', content: 'Hello Widget', modifiers: { font: 'title', color: '#FFFFFF' } }
  ]
};

renderWidget(JSON.stringify(widget));''',
  ),
  ApiEntry(
    name: 'writeFile',
    category: 'FileSystem',
    signature: 'writeFile(path, content)',
    description: 'Writes content to a script sandbox file path through the virtual file system.',
    returnType: 'string',
    params: [
      ApiParam(name: 'path', type: 'string', description: 'Relative sandbox path.', required: true),
      ApiParam(name: 'content', type: 'string', description: 'File content.', required: true),
    ],
    example: '''writeFile('shared/cache/profile.json', JSON.stringify({ name: 'Alex' }));''',
  ),
  ApiEntry(
    name: 'readFile',
    category: 'FileSystem',
    signature: 'readFile(path)',
    description: 'Reads file content from the virtual file system.',
    returnType: 'string',
    params: [
      ApiParam(name: 'path', type: 'string', description: 'Relative sandbox path.', required: true),
    ],
    example: '''const data = readFile('shared/cache/profile.json');
console.log(data);''',
  ),
  ApiEntry(
    name: 'setTimeout',
    category: 'Timers',
    signature: 'setTimeout(cb, ms)',
    description: 'Schedules a callback to run after a delay.',
    returnType: 'number',
    params: [
      ApiParam(name: 'cb', type: 'function', description: 'Callback to run.', required: true),
      ApiParam(name: 'ms', type: 'number', description: 'Delay in milliseconds.', required: true),
    ],
    example: '''setTimeout(function() {
  console.log('Delayed hello');
}, 1000);''',
  ),
  ApiEntry(
    name: 'setInterval',
    category: 'Timers',
    signature: 'setInterval(cb, ms)',
    description: 'Schedules a callback repeatedly at the given interval.',
    returnType: 'number',
    params: [
      ApiParam(name: 'cb', type: 'function', description: 'Callback to run.', required: true),
      ApiParam(name: 'ms', type: 'number', description: 'Interval in milliseconds.', required: true),
    ],
    example: '''const timerId = setInterval(function() {
  console.log('Tick');
}, 5000);''',
  ),
  ApiEntry(
    name: 'clearTimeout',
    category: 'Timers',
    signature: 'clearTimeout(id)',
    description: 'Cancels a pending timeout.',
    returnType: 'void',
    params: [
      ApiParam(name: 'id', type: 'number', description: 'Timeout identifier.', required: true),
    ],
    example: '''const id = setTimeout(() => console.log('Won't run'), 5000);
clearTimeout(id);''',
  ),
  ApiEntry(
    name: 'clearInterval',
    category: 'Timers',
    signature: 'clearInterval(id)',
    description: 'Cancels a repeating interval.',
    returnType: 'void',
    params: [
      ApiParam(name: 'id', type: 'number', description: 'Interval identifier.', required: true),
    ],
    example: '''const id = setInterval(() => console.log('Tick'), 1000);
clearInterval(id);''',
  ),
];
