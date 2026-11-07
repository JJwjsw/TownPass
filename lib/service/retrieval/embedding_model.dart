import 'package:llamadart/llamadart.dart';

class EmbeddingModel {
  final _engine = LlamaEngine(LlamaBackend());
  Future<void> load(String path) async {
    LlamaLogging.configure(level: LlamaLogLevel.none);
    await _engine.setModel(
      LlamaModel(ModelSource.path(path)),
      params: const ModelParams(
        contextSize: 2048,
        batchSize: 2048,
        microBatchSize: 2048,
        gpuLayers: 0,
        preferredBackend: GpuBackend.cpu,
        numberOfThreads: 4,
        numberOfThreadsBatch: 4,
      ),
    );
  }

  Future<List<double>> query(String text) =>
      _engine.embed('task: search result | query: $text', normalize: true);
  Future<List<double>> document(String title, String text) =>
      _engine.embed('title: none | text: $title:$text', normalize: true);
  Future<void> dispose() => _engine.dispose();
}
