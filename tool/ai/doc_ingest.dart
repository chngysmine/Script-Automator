import 'dart:io';
import 'dart:convert';

/// A tool to harvest documentation from the codebase for the AI RAG system.
/// Usage: dart tool/ai/doc_ingest.dart
void main() async {
  stdout.writeln("🤖 Script Automator AI: Starting Knowledge Ingestion...");

  final rootDir = Directory('lib');
  if (!rootDir.existsSync()) {
    stderr.writeln("❌ Error: 'lib' directory not found.");
    exit(1);
  }

  final marketing = [
    "Scanning Codebase...",
    "Extracting wisdom...",
    "Building Neural Pathways...",
    "Optimizing Synapses...",
  ];

  stdout.writeln(marketing[0]);

  final docs = <Map<String, String>>[];
  int fileCount = 0;

  // 1. Walk the tree
  await for (final file in rootDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      fileCount++;
      final content = await file.readAsString();
      final doc = _extractDocs(content);
      if (doc.isNotEmpty) {
        docs.add({
          'path': file.path,
          'content': doc,
          // 'signature': _extractSignatures(content) // Future
        });
      }
    }
  }

  stdout.writeln(
    "✅ Scanned $fileCount files. Found ${docs.length} documentation blocks.",
  );
  stdout.writeln(marketing[2]);

  // 2. Mock Embedding Generation (Real implementation needs API Key)
  // In production, we would loop through `docs`, call Gemini Embeddings API,
  // and store the vector in SQLite.

  final output = File('tool/ai/knowledge_base.json');
  await output.writeAsString(jsonEncode(docs)); // Temporary flat file storage

  stdout.writeln(
    "💾 Knowledge Base saved to ${output.path} (${(output.lengthSync() / 1024).toStringAsFixed(1)} KB)",
  );
  stdout.writeln("🚀 AI is now 0.1% smarter.");
}

/// Simple Regex-based doc extractor.
/// Captures /// comments and the following declaration line.
String _extractDocs(String content) {
  final buffer = StringBuffer();
  final lines = content.split('\n');

  List<String> currentBlock = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('///')) {
      currentBlock.add(line.substring(3).trim());
    } else {
      if (currentBlock.isNotEmpty) {
        // End of block. Check what it documents (the next line)
        if (line.isNotEmpty &&
            !line.startsWith('@') &&
            !line.startsWith('//')) {
          // It's likely a class/method signature
          buffer.writeln("--- DOC: $line ---");
          buffer.writeln(currentBlock.join('\n'));
          buffer.writeln();
        }
        currentBlock = [];
      }
    }
  }
  return buffer.toString();
}
